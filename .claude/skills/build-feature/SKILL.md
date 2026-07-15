---
name: build-feature
description: Implements a feature end-to-end for the FinTrack app by orchestrating planner, coder, and tester as three independent subagents, with a hard file-lane separation between coder (production code) and tester (test code). Use for any non-trivial app feature work instead of implementing directly.
---

You are running the `/build-feature` skill for the FinTrack money-planning app.

Take the feature description passed as this skill's argument. If none was given, ask the user for one
before proceeding — don't guess at scope.

**You (the current session) are the sole orchestrator of this pipeline.** None of the three subagents can
see each other, know about each other, or invoke each other — `planner` has no `Agent` tool at all, and
neither `coder` nor `tester` do either. Only you hold the full picture across all three; each subagent gets
a self-contained prompt from you and returns its result to you alone.

## Process

1. **Plan.** Invoke `planner` with the feature description verbatim, plus a pointer to `CLAUDE.md` and
   `/home/joaoe/.claude/plans/help-me-plan-an-happy-prism.md` for architecture/data-model context. `planner`
   is read-only and returns a concrete plan (files to change, behavior, what to test) — nothing more.
2. **Implement.** Invoke `coder` yourself with the plan: be specific about which files/screens are in
   scope, and remind it that it owns `app/src/main/**` only. Do not mention `tester` or `planner` in this
   prompt — `coder` needs only the plan, not the shape of the pipeline around it.
3. **Verify.** Once `coder` reports back, invoke `tester` yourself with a clear, self-contained description
   of what changed and what to verify — synthesize this from the plan and `coder`'s report; don't just
   forward `coder`'s raw output, and don't reference `coder` or `planner` by name. Remind it that it owns
   all test code (`app/src/test/**`, `app/src/androidTest/**`) and should write real tests, not just run
   existing ones.
4. **Loop on failure.** If `tester` reports failures, invoke `coder` again yourself with the specific
   failure details (test name, error, `tester`'s hypothesis if it has one). Repeat from step 3. Cap this at
   a few rounds — if it isn't converging, stop and report what's blocking rather than looping indefinitely.
   Only go back to `planner` if the failures reveal the plan itself was wrong, not just the implementation.
5. **Report.** Summarize for the user yourself: what changed, whether tests ultimately pass, and anything
   worth human attention (ambiguous requirements, things deferred, permission/hook denials that looked
   wrong for the task). Do not implement the feature yourself — the entire point of this skill is to
   exercise the pipeline with the file-lane separation actually enforced and the orchestration held
   entirely at your level, not delegated into any subagent.

Mention that `.claude/logs/agent-activity.jsonl` has the full handoff trail if the user wants to inspect how
the pipeline ran.
