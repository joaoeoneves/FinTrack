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

DIFF_CONTENT=$( { git diff --cached -U0 2>/dev/null; git diff -U0 2>/dev/null; } )

# A brand-new file has no diff until after it's staged (`git add newfile &&
# git commit` in one call would slip past a diff-only check), so also scan
# the raw contents of every untracked/modified/staged file directly. This
# naturally skips gitignored files (e.g. google-services.json) since
# `git status` omits them unless force-added, in which case they already
# show up in the staged diff above.
FILE_CONTENT=""
while IFS= read -r f; do
  [ -f "$f" ] && FILE_CONTENT="${FILE_CONTENT}
$(cat "$f" 2>/dev/null)"
done < <(git status --porcelain=v1 --untracked-files=all 2>/dev/null | cut -c4-)

CONTENT="${DIFF_CONTENT}
${FILE_CONTENT}"

PATTERN='-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|"private_key"[[:space:]]*:|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|sk-[A-Za-z0-9]{20,}|xox[baprs]-[A-Za-z0-9-]+|AIza[0-9A-Za-z_-]{35}|eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+|"api_?[Kk]ey"[[:space:]]*:[[:space:]]*"[A-Za-z0-9_-]{16,}"'

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
