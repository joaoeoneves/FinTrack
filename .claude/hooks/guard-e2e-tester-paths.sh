#!/bin/bash
# PreToolUse guard for the `e2e-tester` subagent: only allow writes under
# app/src/androidTest/ or .maestro/ — production code is coder's lane, JVM
# unit tests are unit-tester's lane.
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

if echo "$FILE_PATH" | grep -qE '/src/androidTest/|(^|/)\.maestro/'; then
  exit 0
else
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "e2e-tester may only modify files under src/androidTest or .maestro/ — production code is coder'\''s lane, and JVM unit tests are unit-tester'\''s lane. Report this back to the orchestrating session so it can route the change correctly."
    }
  }'
fi
