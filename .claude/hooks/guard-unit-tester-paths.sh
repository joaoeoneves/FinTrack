#!/bin/bash
# PreToolUse guard for the `unit-tester` subagent: only allow writes under
# app/src/test/ — production code is coder's lane, instrumented/Maestro tests
# are e2e-tester's lane.
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

if echo "$FILE_PATH" | grep -qE '/src/test/'; then
  exit 0
else
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "unit-tester may only modify files under src/test — production code is coder'\''s lane, and instrumented/Maestro tests are e2e-tester'\''s lane. Report this back to the orchestrating session so it can route the change correctly."
    }
  }'
fi
