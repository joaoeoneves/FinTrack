# FinTrack

A monthly expense- and income-tracking Android app, built as both:

1. **A real, "classical" money-planning app** — no gimmicks, no AI features at runtime. It never calls the
   Claude/Anthropic API from the app itself; it's just a normal Kotlin/Compose/Firebase app.
2. **A hands-on playground for Claude Code's own developer tooling** — subagents, hooks, skills, and MCP
   servers — used as real, load-bearing parts of how this codebase gets built, not a demo bolted on the
   side. Everything under [`.claude/`](.claude/) in this repo is a working example, not a template.

This README covers both halves: the app itself, and the AI-assisted development setup used to build it.

---

## Table of contents

- [The app](#the-app)
  - [Features](#features)
  - [Tech stack](#tech-stack)
  - [Architecture](#architecture)
  - [Data model](#data-model--firestore)
  - [Getting started](#getting-started)
  - [Common commands](#common-commands)
  - [Testing](#testing)
  - [CI](#ci)
- [AI-assisted development](#ai-assisted-development)
  - [Philosophy](#philosophy)
  - [Subagents](#subagents-plannercoderunit-testere2e-testervalidator)
  - [Skills](#skills)
  - [Hooks](#hooks)
  - [MCP servers](#mcp-servers)
  - [Activity log](#activity-log)

---

## The app

### Features

- **Expense tracking** — add/edit/delete expenses with a name, amount, one of four fixed categories
  (Transfer, Investments, Shopping, Recurring), date, and an optional note.
- **Income tracking** — a separate, parallel entity (free-text source like "Salary" or "Freelance" instead
  of a fixed category), kept intentionally independent of expenses so it could be added later with zero
  risk to the existing expense code.
- **Dashboard** — time-range filters (1 week / 1 month / 3 months / 6 months / 1 year), a pie chart of
  spend by category, the last 5 expenses and last 5 income entries, and a **net balance** figure (income
  minus expenses) for the selected range.
- **Per-category budget limits** — set a monthly limit per category; the Dashboard shows progress bars
  against the current calendar month (independent of the rolling time-range filter) with an over-budget
  visual state.
- **Full expense/income lists** — swipe-to-dismiss delete with an Undo snackbar, plus a trash-icon button
  for discoverability.
- **CSV import/export** — for expenses (income CSV support is a deliberate fast-follow, not yet built).
- **Google Sign-In** via Credential Manager (not the legacy `GoogleSignInClient` API) + Firebase Auth.
- **Dark mode** — a full, intentional Material 3 dark color scheme (not an auto-inverted afterthought),
  following the system setting by default, with a manual light/dark override in the Dashboard's overflow
  menu.
- **Offline-friendly** — Firestore's built-in local cache is the only persistence layer; there's no local
  Room database, so data survives offline use and syncs back once reconnected.

### Tech stack

| Layer | Choice |
|---|---|
| Language | Kotlin 2.2 |
| UI | Jetpack Compose + Material 3 |
| Architecture | MVVM — ViewModels hold state/logic, composables stay declarative |
| Async | Coroutines + `Flow`, `StateFlow` for UI state (`collectAsStateWithLifecycle`) |
| DI | Hilt |
| Navigation | Compose Navigation, type-safe routes |
| Auth | Firebase Auth + Google Sign-In via `androidx.credentials` (Credential Manager) |
| Persistence | Firebase Firestore only — no Room/local database |
| Lint/format | ktlint + detekt |
| Unit tests | JUnit4 + Robolectric (where Android framework classes are needed, e.g. `SharedPreferences`) |
| E2E tests | [Maestro](https://maestro.mobile.dev) |
| CI | GitHub Actions |

Min SDK 24, target/compile SDK 36, Java 11 source/target compatibility.

### Architecture

Single module (`:app`), package `com.joaoeoneves.fintrack`, organized as:

```
app/src/main/java/com/joaoeoneves/fintrack/
├── ui/            Compose screens and components (dashboard, expense/, income/, auth/, theme/, ...)
├── data/          Repository implementations (Firestore + Fake), CSV import/export
├── domain/        Domain models and repository interfaces
├── di/            Hilt modules
app/src/test/          Unit tests (JVM, mirrors the app/src/main package structure)
app/src/androidTest/   Instrumented tests
.maestro/              E2E flows (YAML), run against a real emulator/device
```

Each repository has a real Firestore-backed implementation and a `Fake*` in-memory implementation (used in
unit tests), bound via Hilt in `di/RepositoryModule.kt`. Cross-cutting state (auth, theme preference) is
resolved once in `MainActivity` and threaded down through the nav graph as plain callback/value parameters
— not re-resolved via `hiltViewModel()` inside individual nav destinations, which could otherwise pick up a
different, nav-entry-scoped instance.

### Data model (Firestore)

```
users/{uid}/expenses/{expenseId}
  name: string
  amountCents: number       // integer minor units — avoids float rounding errors
  category: string          // TRANSFER | INVESTMENTS | SHOPPING | RECURRING
  date: timestamp
  note: string | null
  createdAt / updatedAt: timestamp

users/{uid}/income/{incomeId}
  source: string            // free text, e.g. "Salary", "Freelance" — not a fixed enum
  amountCents: number
  date: timestamp
  note: string | null
  createdAt / updatedAt: timestamp

users/{uid}/budgets/{categoryName}
  limitCents: number
  updatedAt: timestamp
```

Security rules ([`firestore.rules`](firestore.rules)) restrict every collection to
`request.auth.uid == userId` — a user can only ever read/write their own documents.

### Getting started

1. **Firebase project**: create one, register an Android app with package `com.joaoeoneves.fintrack`,
   enable Google Sign-In in Authentication, create a Firestore database, and deploy `firestore.rules`.
   Download `google-services.json` into `app/` — it's gitignored and never committed (CI uses a
   placeholder; see [CI](#ci)).
2. **SHA-1**: add your debug (and release) signing certificate's SHA-1 to the Firebase Android app config
   (required for Google Sign-In) — `./gradlew signingReport` prints it.
3. **JDK 21** and `ANDROID_HOME` pointing at an installed Android SDK.
4. Build and run:
   ```
   ./gradlew assembleDebug
   ./gradlew installDebug   # with a device/emulator connected
   ```

### Common commands

Run from the repository root via the Gradle wrapper:

| Command | Purpose |
|---|---|
| `./gradlew assembleDebug` | Build debug APK |
| `./gradlew assembleRelease` | Build release APK |
| `./gradlew installDebug` | Install debug build on a connected device/emulator |
| `./gradlew test` | Run JVM unit tests (`app/src/test`) |
| `./gradlew test --tests "..."` | Run a single unit test |
| `./gradlew connectedAndroidTest` | Run instrumented tests (needs a connected device/emulator) |
| `./gradlew ktlintCheck` | Lint (formatting) |
| `./gradlew detekt` | Lint (static analysis) |
| `./gradlew check` | Full check: lint + tests |
| `./gradlew clean` | Clean build outputs |

### Testing

Three layers, deliberately kept separate:

1. **Unit tests** (`app/src/test`) — JVM, run against `Fake*Repository` implementations, no device needed.
   Robolectric is used where a real Android framework class is unavoidable (e.g. `SharedPreferences`).
2. **Instrumented tests** (`app/src/androidTest`) — on-device/emulator, currently minimal; most real
   on-device verification happens through Maestro instead (see below).
3. **Maestro E2E flows** (`.maestro/*.yaml`) — YAML flows driven against a real emulator, using semantic
   element matching (by visible text/content-description) rather than brittle coordinates or resource IDs.
   Run with `maestro test .maestro/<flow>.yaml`, or author/replay them interactively through the Maestro MCP
   server (see below). Existing flows: `golden-path.yaml` (sign-in → add expense → dashboard → full list →
   edit → delete → filters) and `income-tracking.yaml` (income add → net balance → delete/undo).

### CI

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs on every push/PR to `main`: checkout → JDK 21 →
Gradle → `ktlintCheck` → `detekt` → `testDebugUnitTest` → `assembleDebug`. Since `app/google-services.json`
is a real, gitignored credential, CI writes a shape-compatible **placeholder** (fake project ID, fake OAuth
client, fake API key) as a workflow step — just enough for the `google-services` Gradle plugin's presence
check and for compiling, since unit tests run against Fake repositories and never make real Firestore
calls. Instrumented/Maestro tests are intentionally kept out of this CI job (booting an emulator in CI is
slow and flake-prone) and are run manually instead.

---

## AI-assisted development

This repo doubles as a working example of Claude Code's agentic development features. Everything below is
real configuration in this repo (`.claude/`, `.mcp.json`), not illustrative pseudo-code — you can read the
actual files.

### Philosophy

Most non-trivial feature work in this repo is driven through a five-subagent pipeline
(**planner → coder → unit-tester → e2e-tester → validator**) rather than implemented directly in the main
session, with three properties enforced structurally, not just by convention or prompt etiquette:

- **File-lane separation**: `coder` can only ever touch production code (`app/src/main/**`); `unit-tester`
  can only ever touch JVM unit tests (`app/src/test/**`); `e2e-tester` can only ever touch instrumented/
  Maestro tests (`app/src/androidTest/**`, `.maestro/**`). Each is enforced by a `PreToolUse` hook that
  denies the others' file paths outright — a rogue or confused agent can't just "fix" a failing test by
  editing the test instead of the underlying bug, because it structurally cannot reach that file.
- **No nested delegation**: the main Claude Code session is the *sole* orchestrator. None of the five
  subagents can see, know about, or invoke one another — none of them has the `Agent` tool, including
  `validator`. Each subagent gets a self-contained prompt and reports back to the main session alone; only
  the main session holds the full picture across the pipeline and decides where a fix gets routed.
- **Diagnose/fix separation**: `validator` only runs checks (lint, detekt, build, CI pipeline status) and
  reports a punch list of findings grouped by which agent's lane owns each one. It cannot edit a single
  file, even for a one-line fix — that decision and the actual edit always go through the owning agent.

### Subagents (`planner`/`coder`/`unit-tester`/`e2e-tester`/`validator`)

Defined in [`.claude/agents/`](.claude/agents/), normally invoked via `/build-feature` or `/validate` (see
[Skills](#skills)):

| Agent | Tools | Role | File lane |
|---|---|---|---|
| [`planner`](.claude/agents/planner.md) | `Read, Grep, Glob` | Reads the codebase/plan doc and returns a concrete implementation plan, split into a unit-test tier and an E2E tier. Read-only — never edits, never delegates. | none |
| [`coder`](.claude/agents/coder.md) | `Read, Edit, Write, Bash, Grep, Glob` + `firebase`, `context7` MCP | Implements production code from a plan handed to it directly by the main session. | `app/src/main/**` (+ top-level build files) |
| [`unit-tester`](.claude/agents/unit-tester.md) | `Read, Edit, Write, Bash, Grep, Glob` | Writes and runs real JVM unit tests for the behavior described — happy path plus finance-relevant edge cases. | `app/src/test/**` |
| [`e2e-tester`](.claude/agents/e2e-tester.md) | `Read, Edit, Write, Bash, Grep, Glob` + `firebase`, `maestro` MCP | Functional/instrumented verification driving a real emulator via Maestro (or a Compose `androidTest` when device automation isn't needed) — required whenever a device is available, not "if convenient." | `app/src/androidTest/**`, `.maestro/**` |
| [`validator`](.claude/agents/validator.md) | `Read, Bash, Grep, Glob` + `firebase` MCP | Read-only diagnostic pass: ktlint, detekt, Android lint, fast compile check, CI pipeline status, Firestore rules validity. Reports a punch list routed by lane — never edits anything itself. | none |

The main session orchestrates directly: invoke `planner` for a plan → invoke `coder` with that plan →
invoke `unit-tester` to verify the logic → invoke `e2e-tester` to verify it end-to-end on a real app →
invoke `validator` as a final gate → loop back to whichever agent owns a failure (from either a test tier or
`validator`'s punch list) with specific details → report a final summary to the human. This loop is spelled
out in the `/build-feature` skill, not left to each agent's own judgment about who to call next.

### Skills

Defined in [`.claude/skills/`](.claude/skills/):

- **[`/build-feature "<description>"`](.claude/skills/build-feature/SKILL.md)** — the entry point for
  non-trivial feature work. Runs the full planner → coder → unit-tester → e2e-tester → validator loop
  described above.
- **[`/validate`](.claude/skills/validate/SKILL.md)** — standalone health check outside of a feature build:
  invokes `validator` (e.g. against a specific failing CI run) and routes its findings to
  `coder`/`unit-tester`/`e2e-tester` as needed.
- **[`/seed-data`](.claude/skills/seed-data/SKILL.md)** — generates a realistic multi-month sample CSV
  (varied across all four expense categories) and imports it, so the dashboard's filters/charts have real
  data to exercise without tedious manual entry.

### Hooks

Defined in [`.claude/hooks/`](.claude/hooks/) and wired up in [`.claude/settings.json`](.claude/settings.json):

| Hook | Trigger | Purpose |
|---|---|---|
| `guard-coder-paths.sh` | `coder`'s own `PreToolUse` on `Edit\|Write\|MultiEdit` | Denies any write under `src/test/`, `src/androidTest/`, or `.maestro/` — those are `unit-tester`'s and `e2e-tester`'s lanes. |
| `guard-unit-tester-paths.sh` | `unit-tester`'s own `PreToolUse` on `Edit\|Write\|MultiEdit` | Denies any write outside `src/test/` — production code is `coder`'s lane, instrumented/Maestro tests are `e2e-tester`'s. |
| `guard-e2e-tester-paths.sh` | `e2e-tester`'s own `PreToolUse` on `Edit\|Write\|MultiEdit` | Denies any write outside `src/androidTest/` or `.maestro/` — production code is `coder`'s lane, JVM unit tests are `unit-tester`'s. |
| `guard-no-secrets-commit.sh` | Project-wide `PreToolUse` on `Bash` (git commit/add) | Greps staged content for private-key/API-token patterns and blocks the commit if found. |
| `lint-kotlin.sh` | Project-wide `PostToolUse` on `Edit\|Write\|MultiEdit` matching `*.kt` | Runs ktlint/detekt immediately after any `.kt` edit, so formatting/lint issues surface during the edit, not just at CI time. |
| `log-agent-activity.sh` | Project-wide `SubagentStart`/`SubagentStop` | Appends a one-line JSON record of every subagent invocation to `.claude/logs/agent-activity.jsonl` (gitignored). |

`validator` has no Edit/Write tools at all, so it needs no path guard.

### MCP servers

Registered project-wide in [`.mcp.json`](.mcp.json):

| Server | What it is | Used for |
|---|---|---|
| **[Firebase](https://firebase.google.com/docs/cli/mcp-server)** (`firebase-tools experimental:mcp`, official) | Firebase's own experimental MCP server, run via `npx` | Inspecting/mutating real Firestore documents, checking and deploying security rules, checking Auth users — used by `coder` (verifying an implementation matches real data), `e2e-tester` (verifying a write actually landed correctly), `validator` (checking security rules validity), and by the main session for reviewing/deploying rules changes (a production action, always done with explicit human confirmation, never delegated to a subagent). |
| **[Context7](https://context7.com)** (hosted HTTP, official) | Up-to-date library documentation server | Current Compose/Firebase Kotlin SDK API details for `coder`, since both move fast enough to outpace training data. |
| **[Maestro](https://maestro.mobile.dev)** (`maestro mcp`, official CLI) | Mobile/web UI test automation — declarative YAML flows, semantic element matching, screenshot/inspect tools | `e2e-tester`'s primary tool for the "functional/emulator" verification tier: driving the real app on a real emulator, inspecting the view hierarchy, taking screenshots, and authoring/running reusable `.maestro/*.yaml` flows instead of one-off ad hoc taps. |

`ANDROID_HOME` (`/home/joaoe/Android/Sdk`) and the Maestro CLI (`/home/joaoe/.maestro/bin/maestro`) are
expected to be available in the shell environment for the Maestro MCP server and `connectedAndroidTest` to
work.

### Activity log

Every subagent invocation (start and stop, across the whole pipeline) is appended as a JSON line to
`.claude/logs/agent-activity.jsonl` (gitignored — local-only) with a timestamp, agent type, agent ID, and a
snippet of its last message. Useful for watching how a `/build-feature` run actually unfolded after the
fact, e.g. `tail -f .claude/logs/agent-activity.jsonl` while a feature is being built.
