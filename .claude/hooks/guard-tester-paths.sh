#!/bin/bash
# PreToolUse guard for the `tester` subagent: deny writes to anything outside
# test code. Production code belongs exclusively to the `coder` agent's lane.
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

if echo "$FILE_PATH" | grep -qE '/src/(test|androidTest)/|(^|/)\.maestro/'; then
  exit 0
else
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "tester may only modify files under src/test, src/androidTest, or .maestro/ — production code is the coder agent'\''s lane. Report this back to the orchestrating session so it can route the change to coder instead."
    }
  }'
fi
