---
name: build-feature
description: Implements a feature end-to-end for the FinTrack app by orchestrating planner, coder, unit-tester, e2e-tester, and validator as five independent subagents, with a hard file-lane separation between coder (production code), unit-tester (JVM tests), and e2e-tester (instrumented/Maestro tests). Use for any non-trivial app feature work instead of implementing directly.
---

You are running the `/build-feature` skill for the FinTrack money-planning app.

Take the feature description passed as this skill's argument. If none was given, ask the user for one
before proceeding — don't guess at scope.

**You (the current session) are the sole orchestrator of this pipeline.** None of the five subagents can
see each other, know about each other, or invoke each other — none of them has the `Agent` tool. Only you
hold the full picture across all five; each subagent gets a self-contained prompt from you and returns its
result to you alone.

## Process

1. **Plan.** Invoke `planner` with the feature description verbatim, plus a pointer to `CLAUDE.md` and
   `/home/joaoe/.claude/plans/help-me-plan-an-happy-prism.md` for architecture/data-model context. `planner`
   is read-only and returns a concrete plan (files to change, behavior, what to test — split into a
   unit-test tier and an E2E tier) — nothing more.
2. **Implement.** Invoke `coder` yourself with the plan: be specific about which files/screens are in
   scope, and remind it that it owns `app/src/main/**` only. Do not mention the other agents in this
   prompt — `coder` needs only the plan, not the shape of the pipeline around it.
3. **Unit-test.** Once `coder` reports back, invoke `unit-tester` with a clear, self-contained description
   of what changed and what to verify — synthesize this from the plan's unit-test tier and `coder`'s
   report; don't just forward raw output, and don't reference other agents by name. Remind it that it owns
   `app/src/test/**` and should write real tests, not just run existing ones.
4. **E2E-test.** Only once `unit-tester` reports a pass, invoke `e2e-tester` with the plan's E2E tier and a
   summary of what changed. Remind it that it owns `app/src/androidTest/**` and `.maestro/**`. Skip this
   step only if `planner` explicitly flagged the feature as having no meaningful E2E surface — say so in
   your final report if you skip it.
5. **Loop on test failure.** If `unit-tester` or `e2e-tester` reports failures, invoke `coder` again with
   the specific failure details (test name, error, the tester's hypothesis if it has one), then re-run the
   failing tier (and anything after it) once `coder` reports back. Cap this at a few rounds — if it isn't
   converging, stop and report what's blocking rather than looping indefinitely. Only go back to `planner`
   if the failures reveal the plan itself was wrong, not just the implementation.
6. **Validate.** Once both test tiers pass (or E2E was explicitly skipped), invoke `validator` as a final
   gate: ktlint, detekt, and a fast compile check at minimum, covering every file touched across the whole
   pipeline. `validator` is read-only and returns a punch list grouped by which lane owns each fix, if any.
7. **Loop on validation failure.** For each item in `validator`'s punch list, invoke the agent it named
   (`coder`, `unit-tester`, or `e2e-tester`) with the specific finding (file, rule, message). Once fixed,
   re-invoke `validator` to confirm clean before moving on. Cap this the same way as step 5.
8. **Report.** Summarize for the user yourself: what changed, whether tests and validation ultimately pass,
   and anything worth human attention (ambiguous requirements, things deferred, permission/hook denials that
   looked wrong for the task, validator findings routed to a human instead of an agent). Do not implement
   the feature yourself — the entire point of this skill is to exercise the pipeline with the file-lane
   separation actually enforced and the orchestration held entirely at your level, not delegated into any
   subagent. Ask before committing/pushing, per standard git conventions.

Mention that `.claude/logs/agent-activity.jsonl` has the full handoff trail if the user wants to inspect how
the pipeline ran.
