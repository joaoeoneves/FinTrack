---
name: validate
description: Diagnoses and fixes lint/detekt/build/CI-pipeline problems for the FinTrack app by invoking the read-only validator subagent, then routing each finding to the agent whose lane owns it (coder, unit-tester, or e2e-tester). Use for ad hoc health checks — "check why the pipeline failed," "is this clean before we ship," a specific failing CI run — outside of a /build-feature run.
---

You are running the `/validate` skill for the FinTrack money-planning app.

Take whatever scope was passed as this skill's argument (e.g. a specific CI run/PR, "check why the pipeline
failed", or nothing at all for a general clean-before-ship check). If genuinely ambiguous — you can't tell
whether the user wants a specific failure diagnosed or a general sweep — ask before proceeding.

**You (the current session) are the sole orchestrator.** `validator` cannot edit files or invoke any other
agent — it only diagnoses and routes. You do the actual delegating to `coder`, `unit-tester`, or
`e2e-tester`, the same way `/build-feature` does.

## Process

1. **Diagnose.** Invoke `validator` with the scope (a specific run ID/URL if the user gave one, or "general
   health check: ktlint, detekt, fast compile" if not). It returns a punch list grouped by lane, or a clean
   bill of health.
2. **Nothing to fix?** Report that back to the user and stop — don't manufacture work.
3. **Route each finding.** For every item in the punch list, invoke the agent `validator` named (`coder`,
   `unit-tester`, or `e2e-tester`) with the specific finding: file, rule/error, and message. Don't forward
   the whole punch list to every agent — each agent should only see the findings that are actually theirs.
   Items `validator` flagged as not belonging to any agent (flaky infra, workflow config, transient
   failures) go back to the user instead — don't force those into a lane.
4. **Re-verify.** Once all routed fixes report back, re-invoke `validator` with the same scope to confirm
   clean. If it finds something new or unresolved, loop once or twice more; if it isn't converging, stop and
   report what's still blocking rather than looping indefinitely.
5. **Report.** Summarize for the user: what was broken, what got fixed and by which agent, and the final
   validator result. If the original scope was a specific CI run, confirm whether re-running that pipeline
   is expected to pass now. Ask before committing/pushing, per standard git conventions — this skill fixes
   the working tree, it doesn't assume you should ship it.

Mention that `.claude/logs/agent-activity.jsonl` has the full handoff trail if the user wants to inspect how
the routing ran.
