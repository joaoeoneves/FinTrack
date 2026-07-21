#!/bin/bash
# PreToolUse guard for the `coder` subagent: deny writes to test code.
# Tests belong exclusively to the `unit-tester`/`e2e-tester` agents' lanes.
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

if echo "$FILE_PATH" | grep -qE '/src/(test|androidTest)/|(^|/)\.maestro/'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "coder may not modify test files under src/test, src/androidTest, or .maestro/ — src/test is unit-tester'\''s lane and src/androidTest/.maestro is e2e-tester'\''s lane. Report this back to the orchestrating session so it can route the change to the correct agent instead."
    }
  }'
else
  exit 0
fi
