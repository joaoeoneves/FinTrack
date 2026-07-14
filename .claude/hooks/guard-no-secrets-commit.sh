#!/bin/bash
# PreToolUse guard on Bash: blocks `git add`/`git commit` if staged or
# about-to-be-staged content looks like a private key or API token.
# Applies globally (main session and every subagent) — not agent-specific.
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if ! echo "$COMMAND" | grep -qE '\bgit[[:space:]]+(commit|add)\b'; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR}" 2>/dev/null || exit 0

CONTENT=$( { git diff --cached -U0 2>/dev/null; git diff -U0 2>/dev/null; } )

PATTERN='-----BEGIN (RSA |EC )?PRIVATE KEY-----|"private_key"[[:space:]]*:|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|sk-[A-Za-z0-9]{20,}|xox[baprs]-[A-Za-z0-9-]+'

if echo "$CONTENT" | grep -qE -- "$PATTERN"; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Blocked: staged/working changes look like they contain a private key or API token (e.g. a Firebase service-account JSON). Review before committing — google-services.json and any service-account keys are meant to stay out of git in this project."
    }
  }'
else
  exit 0
fi
