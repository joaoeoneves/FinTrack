# TODO

Backlog of fixes and features. Originally compiled 2026-07-15 by surveying the codebase (TODO/FIXME
markers, the original plan doc vs. what's actually implemented, README gaps, and deprecation warnings
observed across recent builds); extended 2026-07-20 by a full-app review (data/domain layer, UI/UX,
test/CI coverage, security/dependencies); reprioritized 2026-07-20 into explicit tiers below so a new
session can resume at the top without re-triaging. Completed items have been moved to the dated log
at the bottom — the tiers below are the actionable remainder, ordered highest-priority first.

**Resume point:** P1 (correctness/silent-failure bugs) and the earlier data-loss/correctness pass are
fully cleared as of 2026-07-20 — see the completed log. **P2 (security hardening) and P3
(silent-failure hygiene) are fully cleared** as of 2026-07-20 — see the completed log. **Next up is
P4 (UX polish)**.

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
- [x] **[P2] Firestore rules field validation.** `firestore.rules` now validates `request.resource.data`
      on every `create`/`update`, not just `request.auth.uid`: `amountCents`/`limitCents` must be a
      positive int, `category` (expenses) and the budget document id (which doubles as the category) must
      be one of the four known `ExpenseCategory` values, `date` must be a `timestamp`, and `name`/`source`
      must be a non-empty bounded string. Validated with
      `mcp__firebase__firebase_validate_security_rules` (no errors) and deployed live to the
      `agenticusage-d7ce3` Firebase project via `firebase_deploy` (firestore only). Done 2026-07-20.
- [x] **[P2] `guard-no-secrets-commit.sh` gaps fixed.** The hook now also scans the raw contents of every
      untracked/modified/staged file from `git status --porcelain`, not just `git diff`/`git diff
      --cached` — closing the gap where a single `git add newfile && git commit` call could slip a
      brand-new file's secret past a diff-only check. Pattern list extended with Google/Firebase API keys
      (`AIza...`), a generic `"apiKey": "..."` JSON field, and JWTs. Manually verified against a synthetic
      Firebase-key-bearing untracked file (blocked) and the real pending changes at the time (not
      blocked). Done 2026-07-20.
- [x] **[P2] R8 re-enabled for release builds.** `app/build.gradle.kts` now sets
      `optimization { enable = true }` in `buildTypes.release` (gated behind
      `android.r8.gradual.support=true` in `gradle.properties`, required by AGP 9.2.1 for this DSL).
      `assembleRelease` shrinks the unsigned APK from ~26MB to ~3.5MB with genuine class/method renaming.
      **Caught a real runtime-only regression during on-device verification**: R8 renamed the
      `TimeRange` enum (`domain/model/TimeRange.kt`), which Navigation-Compose resolves by
      fully-qualified name at NavHost setup for its type-safe `ExpenseList`/`IncomeList` route args
      (`ui/navigation/Routes.kt`) — this crashed the entire authenticated nav graph immediately after
      sign-in on every launch. Fixed with a `-keepnames`/`-keepclassmembers` pair for `TimeRange` in the
      new `app/src/main/keepRules/rules.keep` (AGP 9.x's replacement for the classic
      `proguard-rules.pro` + `proguardFiles()` mechanism). Re-verified end-to-end: signed the release
      APK with the local debug keystore (no signing config exists or was added — ephemeral, for this
      check only), installed on the `agenticusage_test` emulator, signed in, and ran the full
      `.maestro/golden-path.yaml` flow against the release build — passed clean, zero crashes in
      logcat. No other `@Serializable enum class` exists in the codebase, so this was the only instance
      of the bug. Done 2026-07-20.
- [x] **[P3] Malformed Firestore docs now logged instead of silently dropped.** Each repository's
      `toXOrNull()` (`FirestoreExpenseRepository`/`Income`/`Budget`) now calls `Log.w` at every
      early-return point (missing/invalid field, unresolvable category enum) before returning null;
      `toBudgetOrNull()` was restructured into a single `when` expression to stay under detekt's
      `ReturnCount` limit while still logging each case distinctly. Covered by new tests exercising real
      `DocumentSnapshot` instances (via Firestore's own package-private `fromDocument` factory, since no
      mocking library exists in this project) for both well-formed docs (no log) and each malformed
      variant (dropped + `Log.w` fires, verified via Robolectric's `ShadowLog`). Done 2026-07-20.
- [x] **[P3] `CancellationException` no longer swallowed in `ImportExportViewModel`.** Both
      `onImportFileSelected` and `onExportTargetSelected` now `catch (e: CancellationException) { throw
      e }` before their existing catch-all, so cancelling mid-read/write propagates cancellation instead
      of surfacing as a spurious "failed" error. Covered by new tests using throwing test-only
      `ContentProvider`s (`CancellingContentProvider`/`GenericFailureContentProvider`, since
      `ContentResolver.openInputStream/openOutputStream` are `final` and can't be mocked directly)
      proving cancellation propagates while a genuine (non-cancellation) failure still correctly surfaces
      as `Error`. Done 2026-07-20.
- [x] **[P3] `DashboardViewModel`'s `monthRange` no longer stale.** `monthRange` moved from a
      construction-time class-level `val` to a local `val` recomputed fresh inside `budgetProgress()`
      on every `timeRange`/`retryTrigger` emission. `DashboardScreen.kt` also gained a `DisposableEffect`
      that calls `onRetry()` on `ON_RESUME`, so returning to the Dashboard after backgrounding (the
      realistic midnight-rollover case — an always-foregrounded, never-backgrounded overnight session is
      an accepted remaining edge case) refreshes the month range without requiring manual interaction. No
      `delay()`-based polling was introduced inside the ViewModel, since that would hang existing tests'
      `advanceUntilIdle()` calls. Verified via new unit tests plus a live Maestro golden-path run
      including an explicit `KEYCODE_HOME` → relaunch cycle — no crash, Dashboard re-rendered correctly.
      Done 2026-07-20.
- [x] **[P3] `ExpenseListViewModel` query/sort now survive process death.** `query`/`sortOption` switched
      from plain `MutableStateFlow` to `savedStateHandle.getStateFlow(...)`-backed state, with
      `onQueryChanged`/`onSortSelected` now writing through the handle — matching how `timeRange` already
      survived restoration. Covered by a new test simulating process-death recreation (constructing a
      second `ExpenseListViewModel` against the same `SavedStateHandle` instance) confirming both values
      round-trip instead of resetting to defaults. Done 2026-07-20.
