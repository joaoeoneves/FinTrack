#!/bin/bash
# SubagentStart/SubagentStop hook: appends a one-line JSON record of every
# subagent handoff so the planner -> coder -> tester pipeline can be watched
# after the fact. Project-level (settings.json) mechanism, distinct from the
# per-agent frontmatter hooks used for path enforcement.
INPUT=$(cat)
LOG_DIR="${CLAUDE_PROJECT_DIR}/.claude/logs"
mkdir -p "$LOG_DIR"

echo "$INPUT" | jq -c '{
  time: (now | todate),
  event: .hook_event_name,
  agent_type: .agent_type,
  agent_id: .agent_id,
  last_message: (if .last_assistant_message then .last_assistant_message[0:300] else null end)
}' >> "$LOG_DIR/agent-activity.jsonl"

exit 0
