# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Single-module Android application built with Jetpack Compose and Kotlin. Package/namespace and
application ID: `ptech.joaoe.agenticusage`. Module: `:app`.

## Commands

Run all commands from the repository root using the Gradle wrapper.

- Build debug APK: `./gradlew assembleDebug`
- Build release APK: `./gradlew assembleRelease`
- Run unit tests (JVM, `app/src/test`): `./gradlew test`
- Run a single unit test: `./gradlew test --tests "ptech.joaoe.agenticusage.ExampleUnitTest"`
- Run instrumented tests (`app/src/androidTest`, requires a connected device/emulator): `./gradlew connectedAndroidTest`
- Install debug build on a connected device/emulator: `./gradlew installDebug`
- Full check (lint + tests): `./gradlew check`
- Clean build outputs: `./gradlew clean`

## Architecture

- `app/src/main/java/ptech/joaoe/agenticusage/MainActivity.kt` — single entry-point `ComponentActivity`; sets Compose content directly via `setContent` (no navigation graph or DI framework set up yet).
- `app/src/main/java/ptech/joaoe/agenticusage/ui/theme/` — Compose theme (`Theme.kt`, `Color.kt`, `Type.kt`) following the standard Material 3 theming pattern (`AgenticUsageTheme` wraps composables).
- `app/src/main/AndroidManifest.xml` — declares `MainActivity` as the sole launcher activity.
- `gradle/libs.versions.toml` — central version catalog; add/upgrade dependencies here rather than hardcoding versions in `app/build.gradle.kts`.
- Min SDK 24, target/compile SDK 36, Java 11 source/target compatibility, Kotlin 2.2.10.

This is a money-planning (monthly expense tracking) app, backed by Firebase Auth (Google Sign-In) and
Firestore only (no local Room layer — Firestore's built-in offline cache is sufficient). See
`/home/joaoe/.claude/plans/help-me-plan-an-happy-prism.md` for the full feature/data-model plan.

## Claude Code tooling in this repo

This project doubles as a playground for Claude Code's own dev-workflow features, so most non-trivial
feature work should go through the agent pipeline below rather than being implemented directly:

- **`/build-feature "<description>"`** — the entry point. Delegates to the `planner` subagent, which
  nest-spawns `coder` (implements `app/src/main/**`) and `tester` (writes/runs everything under
  `app/src/test/**` and `app/src/androidTest/**`), looping on failures.
- **`coder` and `tester` cannot edit each other's files.** This is hook-enforced (`.claude/hooks/guard-*-paths.sh`),
  not just a convention — `coder` can never touch test files, `tester` can never touch production code.
- **`/seed-data`** — generates and imports a multi-month sample dataset for exercising the dashboard/filters.
- Every subagent handoff is logged to `.claude/logs/agent-activity.jsonl` (gitignored) via
  `SubagentStart`/`SubagentStop` hooks — useful for watching the planner→coder→tester pipeline run.
- A `PreToolUse` hook blocks `git add`/`git commit` if the diff looks like it contains a private key or API
  token (`.claude/hooks/guard-no-secrets-commit.sh`).
- MCP servers (`.mcp.json`): `firebase` (official, `firebase-tools experimental:mcp` — Firestore/Auth
  inspection), `context7` (current Compose/Firebase Kotlin SDK docs), `android-adb` (community; real
  emulator/device control for `tester`, requires `ANDROID_HOME` set in the shell environment — SDK lives at
  `/home/joaoe/Android/Sdk` on this machine but `ANDROID_HOME` isn't exported yet).
