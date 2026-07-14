#!/bin/bash
# PostToolUse hook on Edit|Write|MultiEdit: runs ktlint's format task after any
# .kt file change, so style issues surface immediately during agent work
# rather than only at CI/build time. No-ops until the ktlint Gradle plugin is
# actually added to the build (see the "Firebase project setup" / data-layer
# implementation step) — safe to enable before that lands.
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

case "$FILE_PATH" in
  *.kt)
    if [ -x "${CLAUDE_PROJECT_DIR}/gradlew" ] && grep -rq "ktlint" "${CLAUDE_PROJECT_DIR}/build.gradle.kts" 2>/dev/null; then
      "${CLAUDE_PROJECT_DIR}/gradlew" -p "${CLAUDE_PROJECT_DIR}" ktlintFormat --quiet >&2 || true
    fi
    ;;
esac

exit 0
