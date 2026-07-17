#!/bin/bash
# PreToolUse hook for Maestro test-execution MCP tools (mcp__maestro__run,
# mcp__maestro__run_on_cloud): disables Android animation scales on every
# connected device/emulator before the flow runs. Animation scale is a
# per-boot-image system setting, so a cold-booted/reset emulator reverts to
# the default (1.0) even if it was disabled in a previous session -- this
# hook re-applies it idempotently before every actual test run instead of
# relying on a one-time manual `adb shell settings put global` invocation.
# Never blocks the tool call: if adb isn't available or no device is
# connected, it exits 0 silently and lets Maestro's own error reporting
# handle that case.
cat >/dev/null

ADB="${ANDROID_HOME:-$HOME/Android/Sdk}/platform-tools/adb"
if ! command -v "$ADB" >/dev/null 2>&1; then
  ADB="adb"
fi
if ! command -v "$ADB" >/dev/null 2>&1; then
  exit 0
fi

SERIALS=$("$ADB" devices 2>/dev/null | awk 'NR>1 && $2=="device" {print $1}')

for SERIAL in $SERIALS; do
  "$ADB" -s "$SERIAL" shell settings put global window_animation_scale 0 2>/dev/null
  "$ADB" -s "$SERIAL" shell settings put global transition_animation_scale 0 2>/dev/null
  "$ADB" -s "$SERIAL" shell settings put global animator_duration_scale 0 2>/dev/null
done

exit 0
