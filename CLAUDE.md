# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Single-module Android application built with Jetpack Compose and Kotlin. Package/namespace and
application ID: `com.joaoeoneves.fintrack`. Module: `:app`.

## Commands

Run all commands from the repository root using the Gradle wrapper.

- Build debug APK: `./gradlew assembleDebug`
- Build release APK: `./gradlew assembleRelease`
- Run unit tests (JVM, `app/src/test`): `./gradlew test`
- Run a single unit test: `./gradlew test --tests "com.joaoeoneves.fintrack.ExampleUnitTest"`
- Run instrumented tests (`app/src/androidTest`, requires a connected device/emulator): `./gradlew connectedAndroidTest`
- Install debug build on a connected device/emulator: `./gradlew installDebug`
- Full check (lint + tests): `./gradlew check`
- Run lint only: `./gradlew lint`
- Clean build outputs: `./gradlew clean`

## Architecture

- `app/src/main/java/com/joaoeoneves/fintrack/MainActivity.kt` — single entry-point `ComponentActivity`; sets Compose content directly via `setContent`.
- `app/src/main/java/com/joaoeoneves/fintrack/ui/theme/` — Compose theme (`Theme.kt`, `Color.kt`, `Type.kt`) following the standard Material 3 theming pattern (`FinTrackTheme` wraps composables).
- `app/src/main/AndroidManifest.xml` — declares `MainActivity` as the sole launcher activity.
- `gradle/libs.versions.toml` — central version catalog; add/upgrade dependencies here rather than hardcoding versions in `app/build.gradle.kts`.
- Min SDK 24, target/compile SDK 36, Java 11 source/target compatibility, Kotlin 2.2.10.

This is a money-planning (monthly expense tracking) app, backed by Firebase Auth (Google Sign-In) and
Firestore only (no local Room layer — Firestore's built-in offline cache is sufficient). See
`/home/joaoe/.claude/plans/help-me-plan-an-happy-prism.md` for the full feature/data-model plan.

### Target package structure

As feature code lands (via `/build-feature`), organize `app/src/main/java/com/joaoeoneves/fintrack/` into:

- `ui/` — Compose screens and components
- `data/` — repositories, data sources, and models
- `domain/` — use cases and domain models
- `di/` — Hilt dependency injection modules
- `app/src/test/` — unit tests
- `app/src/androidTest/` — instrumented tests

### Code style & conventions

- Use Kotlin idioms (scope functions, extensions, sealed classes) and follow standard Kotlin coding
  conventions.
- All new UI is Jetpack Compose; async work uses coroutines and `Flow`.
- MVVM: ViewModels hold state and logic, composables stay declarative.
- Hilt for dependency injection.
- Sealed classes/interfaces for UI state; data classes for models and DTOs.
- Prefer immutable data (`val` over `var`).

### State management

- `StateFlow` for UI state in ViewModels; collect it in Compose with `collectAsStateWithLifecycle`.
- `remember`/`mutableStateOf` only for local, ephemeral UI state — not app state, which belongs in the
  ViewModel.

### Navigation

- Compose Navigation with type-safe routes, defined in a central navigation graph.
- Pass arguments through routes, not shared/global state.

## Claude Code tooling in this repo

This project doubles as a playground for Claude Code's own dev-workflow features, so most non-trivial
feature work should go through the agent pipeline below rather than being implemented directly. There are
five subagents, each with a single-purpose lane:

- **`planner`** — read-only, breaks a feature request into a concrete plan (files, behavior, what to test
  per tier). Cannot edit files.
- **`coder`** — implements production code under `app/src/main/**`.
- **`unit-tester`** — writes/runs JVM unit tests under `app/src/test/**`.
- **`e2e-tester`** — writes/runs instrumented and Maestro tests under `app/src/androidTest/**` and
  `.maestro/**`.
- **`validator`** — read-only, runs ktlint/detekt/lint/build checks and inspects CI pipeline runs, then
  reports a punch list of findings grouped by which of the other four agents' lane owns the fix. Never
  fixes anything itself.

Entry points:

- **`/build-feature "<description>"`** — the full pipeline: `planner` → `coder` → `unit-tester` →
  `e2e-tester` → `validator`, looping back to whichever agent owns a failure until it's clean.
- **`/validate`** — standalone health check (e.g. "check why the pipeline failed"): invokes `validator`,
  then routes its findings to `coder`/`unit-tester`/`e2e-tester` as needed, without going through a full
  feature build.
- **`/seed-data`** — generates and imports a multi-month sample dataset for exercising the dashboard/filters.

Rules that hold across all five:

- **No subagent can see, know about, or invoke another.** None of the five has the `Agent` tool — nesting
  is disabled for all of them, including `validator`, which only *reports* which lane owns a fix. Only the
  main session (or a skill run by it) holds the full picture across the pipeline and does the actual
  delegating; each subagent gets a self-contained prompt and reports back to the main session alone.
- **`coder`, `unit-tester`, and `e2e-tester` cannot edit each other's files.** This is hook-enforced
  (`.claude/hooks/guard-coder-paths.sh`, `guard-unit-tester-paths.sh`, `guard-e2e-tester-paths.sh`), not
  just a convention — `coder` owns `app/src/main/**` only, `unit-tester` owns `app/src/test/**` only, and
  `e2e-tester` owns `app/src/androidTest/**`/`.maestro/**` only. `validator` has no Edit/Write tools at all,
  so it needs no path guard.
- Every subagent invocation is logged to `.claude/logs/agent-activity.jsonl` (gitignored) via
  `SubagentStart`/`SubagentStop` hooks — useful for watching the main session's orchestration run.
- A `PreToolUse` hook blocks `git add`/`git commit` if the diff looks like it contains a private key or API
  token (`.claude/hooks/guard-no-secrets-commit.sh`).
- MCP servers (`.mcp.json`): `firebase` (official, `firebase-tools experimental:mcp` — Firestore/Auth
  inspection, used by `coder`, `e2e-tester`, and `validator`), `context7` (current Compose/Firebase Kotlin
  SDK docs, used by `coder`), `maestro` (real emulator/device E2E test authoring + running for `e2e-tester`
  — semantic element matching, YAML flows under `.maestro/`, e.g. `.maestro/golden-path.yaml`; run manually
  via `maestro test .maestro/<flow>.yaml`). `ANDROID_HOME` is exported in the shell profile
  (`/home/joaoe/Android/Sdk`); the Maestro CLI itself lives at `/home/joaoe/.maestro/bin/maestro`.
