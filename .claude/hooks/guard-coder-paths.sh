#!/bin/bash
# PreToolUse guard for the `coder` subagent: deny writes to test code.
# Tests belong exclusively to the `tester` agent's lane.
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
      permissionDecisionReason: "coder may not modify test files under src/test, src/androidTest, or .maestro/ — that is the tester agent'\''s lane. Ask planner to delegate this change to tester instead."
    }
  }'
else
  exit 0
fi
