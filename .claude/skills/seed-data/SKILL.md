---
name: seed-data
description: Generates a realistic multi-month sample dataset of expenses for the FinTrack app and imports it, so the dashboard/filters/reports have real data to exercise without manual entry.
---

You are running the `/seed-data` skill for the FinTrack money-planning app.

Generate a CSV with columns `name, amountCents, category, date, note` covering roughly the last 12 months,
with a realistic and varied distribution across the four fixed categories — `Transfer`, `Investments`,
`Shopping`, `Recurring` — so the app's 1-week / 1-month / 3-month / 6-month / 1-year filters each show
meaningfully different data (vary both frequency and amount per category; e.g. `Recurring` should look like
monthly bills at consistent amounts/dates, `Shopping` should be frequent and variable).

Write the CSV to this session's scratchpad directory, then:

- If the app's CSV import flow is already implemented, drive it (via the running app, or by calling the
  underlying import function directly) to load the file.
- If the import flow doesn't exist yet, fall back to writing the documents directly to Firestore under the
  signed-in user's `users/{uid}/expenses` collection using the `firebase` MCP tools, matching the exact
  schema in the plan file.

Report how many rows were generated and successfully imported, and the date range they cover.
