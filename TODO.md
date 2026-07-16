# TODO

Backlog of fixes and features, compiled 2026-07-15 by surveying the codebase (TODO/FIXME markers,
the original plan doc vs. what's actually implemented, README gaps, and deprecation warnings
observed across recent builds). Not prioritized beyond the groupings below — pick items up as
they become relevant.

## Bug fixes / tech debt

- [ ] Migrate deprecated icons (`Icons.Filled.TrendingUp`, `ArrowBack`, `MoreVert`) to
      `Icons.AutoMirrored.Filled.*`. Currently trips compiler warnings in `CategoryDisplay.kt`,
      `AddEditExpenseScreen.kt`, `ExpenseListScreen.kt`, `IncomeListScreen.kt`, `PieChart.kt`,
      `IncomeRow.kt`.
- [ ] Replace deprecated `confirmValueChange` on `rememberSwipeToDismissBoxState` (swipe-to-delete
      in `ExpenseListScreen.kt`/`IncomeListScreen.kt`) — deprecated with no direct replacement;
      current behavior still works but should move to the anchor-based approach before it breaks.
- [ ] Fix `@param` vs `@property` annotation-target warning in `ImportExportViewModel.kt`
      (KT-73255) — either annotate explicitly or add the suggested compiler flag.
- [ ] Remove stock `ExampleUnitTest.kt` / `ExampleInstrumentedTest.kt` — Android-Studio boilerplate
      with zero real coverage value, never cleaned up.
- [ ] Add real instrumented (`androidTest`) coverage for at least the golden path. All on-device
      verification today is manual Maestro, which isn't wired into CI — nothing currently runs an
      on-device check automatically on push.

## Features

- [ ] **Income CSV import/export** — expense CSV already works end-to-end; README explicitly
      calls this out as "a deliberate fast-follow, not yet built."
- [ ] Custom/user-defined expense categories — currently a fixed 4-value enum
      (Transfer/Investments/Shopping/Recurring); real usage will want user-defined categories.
- [ ] Budget periods beyond monthly — `BudgetSection` is hardcoded to "this month" only.
- [ ] Notifications (budget-exceeded alerts, recurring-bill reminders) — Settings has no
      Notifications section yet; natural next entry there.
- [ ] Receipt photo attachment on expenses — would need Firebase Storage wiring.
- [ ] Real multi-currency conversion — currency is explicitly display-only today (no exchange
      rates, no per-item currency tag in Firestore); bigger lift, only worth it if actually wanted.
- [ ] Biometric/app-lock — no lock screen today for what is personal finance data.
- [ ] Full JSON backup/restore, or a PDF monthly report — export currently only covers expenses,
      and only as CSV.
