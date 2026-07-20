# TODO

Backlog of fixes and features. Originally compiled 2026-07-15 by surveying the codebase (TODO/FIXME
markers, the original plan doc vs. what's actually implemented, README gaps, and deprecation warnings
observed across recent builds); extended 2026-07-20 by a full-app review (data/domain layer, UI/UX,
test/CI coverage, security/dependencies); reprioritized 2026-07-20 into explicit tiers below so a new
session can resume at the top without re-triaging. Completed items have been moved to the dated log
at the bottom — the tiers below are the actionable remainder, ordered highest-priority first.

**Resume point:** P1 (correctness/silent-failure bugs) and the earlier data-loss/correctness pass are
fully cleared as of 2026-07-20 — see the completed log. **Next up is P2 (security hardening)**,
starting with Firestore rules validation.

## P2 — Security / data integrity

- [ ] Firestore rules (`firestore.rules`) only check `request.auth.uid == userId` — cross-user isolation
      is solid, but there's no `request.resource.data` validation at all. A modified client can write a
      negative `amountCents`/`limitCents`, an arbitrary `category` string (which then silently
      disappears client-side per the `mapNotNull` finding below), or a `budgets` doc keyed by an invalid
      category. Not a cross-tenant leak, but worth adding type/range/enum checks since there's no backend
      to catch this otherwise.
- [ ] Release build has R8 fully disabled (`app/build.gradle.kts`, `optimization { enable = false }` in
      `buildTypes.release`) — no shrinking or obfuscation on `assembleRelease`. Beyond APK bloat, this
      leaves Firestore collection/field names and app logic trivially readable in a decompiled release
      APK. Worth re-enabling with a proper `proguard-rules.pro` pass before any real release.
- [ ] `.claude/hooks/guard-no-secrets-commit.sh` (dev tooling) has two gaps: a single Bash call doing
      `git add newfile && git commit` can slip a brand-new file's secret past it (nothing is staged yet
      when `git diff`/`git diff --cached` run), and its pattern list has no coverage for Google/Firebase
      API keys (`AIza...`) or generic `apiKey`/JWT patterns — notably the exact credential type
      `google-services.json` uses.

## P3 — Silent-failure hygiene

- [ ] Malformed/partial Firestore documents (bad enum value, wrong field type) are dropped via
      `mapNotNull` with zero error/log signal (`FirestoreExpenseRepository.kt:160-183` and the Income/
      Budget equivalents) — harmless today, but a silent data-loss vector on any future category
      rename or schema change.
- [ ] Import/export's catch-all in `ImportExportViewModel` doesn't special-case
      `CancellationException`, so cancelling mid-operation surfaces as a spurious "failed" error instead
      of propagating cancellation.
- [ ] `DashboardViewModel`'s `monthRange` is computed once at construction — if the Dashboard stays
      subscribed across a midnight/month rollover, budget "spent this month" keeps using the stale range.
- [ ] `ExpenseListViewModel`'s search query/sort option aren't restored via `SavedStateHandle` (unlike
      `timeRange`) — lost on process death.

## P4 — UX polish

- [ ] Date field in Add/Edit Expense/Income only opens the date picker via the small trailing icon, not
      the whole field, despite looking fully tappable.
- [ ] Import/export UI labels ("Import CSV"/"Export CSV" in Settings) don't disclose that only expenses
      are covered today — a user could reasonably believe it's a full backup and lose income data on
      reinstall with no warning. Fix the copy regardless of when income CSV (below) lands.
- [ ] Income list has no search or sort, unlike the Expense list (`ExpenseListViewModel` has both
      `query` and `sortOption`; `IncomeListViewModel` has neither) — a feature-parity gap from Income
      being added later as a parallel feature.
- [ ] Pie chart (`PieChart.kt`) has no accessibility semantics — canvas-drawn donut plus disconnected
      legend rows give TalkBack users no usable representation of the breakdown.

## P5 — Testing / CI gaps

- [ ] CI (`.github/workflows/ci.yml`) runs `ktlintCheck`/`detekt`/`testDebugUnitTest`/`assembleDebug`
      only — no instrumented or Maestro job at all, so nothing on-device ever runs automatically
      (broader than the androidTest item below, which is about coverage that doesn't exist yet; this is
      about wiring what already exists into CI). Confirmed manually on 2026-07-20 (all four `.maestro/`
      flows pass; one flaky no-op tap found and fixed in that pass), but still nothing runs this
      automatically on push.
- [ ] Add real instrumented (`androidTest`) coverage for at least the golden path. All on-device
      verification today is manual Maestro, which isn't wired into CI — nothing currently runs an
      on-device check automatically on push.
- [ ] `CurrencyViewModel` has zero unit tests (its structural sibling `ThemeViewModel` has 6). There's
      also no `FakeLanguageRepository` anywhere (unlike expense/income/budget/auth, which all have one),
      so `SharedPrefsLanguageRepository`'s fallback/locale-mapping logic and
      `SettingsViewModel.setLanguage()` are untested end-to-end — language switching is a real,
      user-facing, completely unverified feature.
- [ ] Budget-editing (`BudgetSection` → `EditBudgetDialog` → `onSetBudget`) has ViewModel-level unit
      tests but zero E2E/Maestro coverage of the actual dialog interaction.
- [ ] `.maestro/settings.yaml`'s Data section opens the import/export file pickers and immediately backs
      out — no flow anywhere actually completes a CSV round-trip through the real UI (only unit-tested
      via `ImportExportViewModelTest`).
- [ ] No Maestro/androidTest coverage of language switching in Settings.
- [ ] `app/config/detekt/baseline.xml` has 131 suppressed findings (`buildUponDefaultConfig = true`) —
      worth periodically triaging down rather than treating the green check as a full bar.

## P6 — Features

Roughly in likely-value order — income CSV closes a known, README-flagged gap; the rest are larger,
more speculative lifts.

- [ ] **Income CSV import/export** — expense CSV already works end-to-end; README explicitly
      calls this out as "a deliberate fast-follow, not yet built." Note: `FirestoreIncomeRepository
      .addIncomeList()` has the same batch-abort/no-partial-progress bug that was fixed on the expense
      side (2026-07-20) — fix that alongside wiring up the income-CSV UI, don't reintroduce it.
- [ ] Custom/user-defined expense categories — currently a fixed 4-value enum
      (Transfer/Investments/Shopping/Recurring); real usage will want user-defined categories.
- [ ] Budget periods beyond monthly — `BudgetSection` is hardcoded to "this month" only.
- [ ] Budget rollover — carry unspent budget into the next month (variant of the item above).
- [ ] Notifications (budget-exceeded alerts, recurring-bill reminders) — Settings has no
      Notifications section yet; natural next entry there.
- [ ] Spending-over-time trend chart on the Dashboard — today's pie chart only breaks spend down by
      category for the selected range; there's no line/bar view of month-over-month trend.
- [ ] Receipt photo attachment on expenses — would need Firebase Storage wiring.
- [ ] Real multi-currency conversion — currency is explicitly display-only today (no exchange
      rates, no per-item currency tag in Firestore); bigger lift, only worth it if actually wanted.
- [ ] Biometric/app-lock — no lock screen today for what is personal finance data.
- [ ] Full JSON backup/restore, or a PDF monthly report — export currently only covers expenses,
      and only as CSV.

---

## Completed

- [x] Migrate deprecated icons (`Icons.Filled.TrendingUp`, `ArrowBack`) to
      `Icons.AutoMirrored.Filled.*` (`MoreVert` turned out to be unused, nothing to migrate there).
      Done 2026-07-16.
- [x] Replace deprecated `confirmValueChange` on `rememberSwipeToDismissBoxState` (swipe-to-delete
      in `ExpenseListScreen.kt`/`IncomeListScreen.kt`) with `LaunchedEffect(dismissState.currentValue)`
      + `snapTo(Settled)`. Done 2026-07-16.
- [x] Fix `@param` vs `@property` annotation-target warning in `ImportExportViewModel.kt`
      (KT-73255) via explicit `@param:ApplicationContext`. Done 2026-07-16.
- [x] Remove stock `ExampleUnitTest.kt` / `ExampleInstrumentedTest.kt`. Done 2026-07-16.
- [x] **[data loss] Edit screen silently wipes a record on a transient load failure.**
      `getExpense`/`getIncome` now return `Result<Expense?>`/`Result<Income?>`, distinguishing a load
      failure (`Result.failure`) from a confirmed not-found (`Result.success(null)`). A load failure now
      surfaces a dedicated `AddEditUiState.Error` state with retry instead of falling through to a blank
      editable form. `updateExpense`/`updateIncome` also switched from an upserting `set(merge)` to
      `.update()`, which fails outright on a missing doc instead of silently overwriting. Done 2026-07-20.
- [x] **[hidden by tests] Fake repositories diverge from real Firestore behavior on update/delete of a
      missing id.** `deleteExpense`/`deleteIncome` now run in a transaction that fails if the doc doesn't
      exist (previously silent no-op), matching the fakes' existing behavior; the fakes were already
      correct here and only needed recompiling against the `getExpense`/`getIncome` signature change.
      Done 2026-07-20.
- [x] **[data loss] CSV round-trip is broken for notes containing newlines**, despite
      `ExpenseCsvWriter`'s doc comment claiming a guaranteed round-trip. `ExpenseCsvParser` now splits the
      raw file into logical records with a quote-aware scanner (only treating `\n`/`\r`/`\r\n` as a row
      separator when not inside an open quoted field) instead of pre-splitting on physical lines, so a
      quoted multi-line note survives import intact. Done 2026-07-20.
- [x] **CSV import rejects Excel/Google Sheets "CSV UTF-8" exports** — a leading BOM is now stripped
      before header matching, so a valid re-exported/edited file is no longer rejected with "Unrecognized
      header." Done 2026-07-20.
- [x] **Bulk CSV import has no partial-progress tracking.** `addExpenses` now returns a `BulkAddResult`
      (succeeded count + optional failure) instead of `Result<Int>`, with the per-chunk try/catch moved
      inside the batch loop so a mid-import failure reports exactly how many rows committed before it.
      The Import UI surfaces a new `PartialFailure` state warning the user that re-importing the same
      file may duplicate the already-committed rows — full content-keyed idempotency was judged out of
      scope for this pass (flagged as a possible future item, see the Income CSV feature item above).
      Done 2026-07-20.
- [x] Bare-date CSV rows (e.g. `"2024-01-15"`, no time component) parse as UTC midnight, landing a
      calendar day earlier on devices with a negative UTC offset. `ExpenseCsvParser.parse` now takes a
      `zone: ZoneId = ZoneId.systemDefault()` parameter threaded to the bare-date fallback, so it lands
      on the calendar day the user actually wrote; the offset-aware full-instant branch (used by the
      app's own export) is unchanged. Done 2026-07-20.
- [x] Sign-out ordering: if `credentialManager.clearCredentialState()` throws, `firebaseAuth.signOut()`
      was never reached — UI reported "sign-out failed" while the user was, confusingly, still logged
      in. Both calls now run independently via `runCatching`; the overall result is driven solely by
      `firebaseAuth.signOut()`'s outcome, so a credential-clear failure no longer masks a real sign-out.
      Done 2026-07-20.
- [x] Fixed a flaky no-op tap in `.maestro/income-tracking.yaml` ("See all income" sitting just past the
      Dashboard's scroll-clip bounds, same root cause already worked around in
      `swipe-delete-check.yaml`) while manually verifying all four `.maestro/` E2E flows on a live
      emulator. Done 2026-07-20.
