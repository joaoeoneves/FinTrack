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

The codebase is currently at the freshly-generated "Empty Activity" template stage — no networking,
persistence, DI, or navigation libraries are wired in yet.
