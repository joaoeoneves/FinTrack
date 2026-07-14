---
name: build-feature
description: Implements a feature end-to-end for the AgenticUsage app through the planner -> coder -> tester subagent pipeline, with a hard file-lane separation between coder (production code) and tester (test code). Use for any non-trivial app feature work instead of implementing directly.
---

You are running the `/build-feature` skill for the AgenticUsage money-planning app.

Take the feature description passed as this skill's argument. If none was given, ask the user for one
before proceeding — don't guess at scope.

Delegate the entire implementation to the `planner` subagent, giving it:

- The feature description, verbatim.
- A pointer to `CLAUDE.md` and `/home/joaoe/.claude/plans/help-me-plan-an-happy-prism.md` for architecture
  and data-model context (screens, the `Expense` model, the category enum, the Firestore layout).
- An explicit instruction that it should nest-spawn `coder` to implement and `tester` to verify, looping
  back to `coder` on any test failure, and return only a final pass/fail summary — not a blow-by-blow of
  every intermediate step.

Do not implement the feature yourself in the main session — the entire point of this skill is to exercise
the planner -> coder -> tester pipeline end to end, with the file-lane separation actually enforced. Once
`planner` returns, relay its summary to the user: what changed, whether `tester` ultimately passed, and
anything flagged for human attention. Mention that `.claude/logs/agent-activity.jsonl` has the full handoff
trail if the user wants to inspect how the agents worked together.
