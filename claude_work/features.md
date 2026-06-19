# Paisa — Feature Plan (from reference screenshots)

This document analyzes the 8 reference screenshots and turns each into a concrete, prioritized
feature spec adapted to Paisa's **existing** architecture (Flutter + Riverpod + go_router +
Phosphor icons, feature-first folders under `mobile/lib/features/`).

We implement **one feature at a time**. Each has: what the screenshot shows → what we build →
where it lives → acceptance criteria.

---

## Screenshot → Feature map (at a glance)

| Screenshot | Reference feature | Our feature | Already have? |
|-----------|-------------------|-------------|---------------|
| 1 | Records (date-grouped txns + month summary) | **F4** | Partial (expenses list) |
| 2 | Interactive donut + breakdown | **F6** | Mostly (donut card) |
| 3 | Budget Planner | **F5** | Partial (budgets screen) |
| 4 | Add txn w/ calculator + Income/Expense/**Transfer** | **F2** | Calc + I/E only |
| 5 | Dark theme | — | ✅ Done |
| 6 | Expense Flow line chart | **F7** | Partial (daily chart) |
| 7 | Multiple Accounts | **F1** | ❌ Missing |
| 8 | Create/Customize Categories | **F3** | Static only |

---

## F1 — Accounts (P0, build first) · _Screenshot 7_

**Reference shows:** A list of account cards — Card, Cash, Investment, Savings, Wallet — each
with a colored icon, a balance, and a `⋯` menu. A header strip shows `[ All Accounts $9,096.28 ]`
with `EXPENSE SO FAR` / `INCOME SO FAR`. An `ADD NEW ACCOUNT` button at the bottom.

**Why first:** Transfers (F2) and per-account balances depend on this. It's the biggest gap.

**What we build:**
- New feature module `mobile/lib/features/accounts/` (data + presentation, mirror existing modules).
- `Account` model: `id, name, type (card/cash/wallet/bank/investment/savings), balance, color, icon, currency`.
- Accounts list screen: total-across-accounts header, account cards, add/edit/delete.
- Add/Edit account sheet (name, type, opening balance, color, icon picker).
- Riverpod `accountsProvider` (start local via shared_preferences/secure storage; wire to server if API exists).
- Every expense/income references an `accountId`; balances recompute from transactions.

**Lives in:** `features/accounts/`, entry via Profile → Finance → Accounts.

**Acceptance:**
- [x] Can create, edit, delete accounts. _(CRUD sheet + soft-delete)_
- [x] Total balance header sums all accounts. _(gradient header)_
- [~] Account balances reflect transactions — **deferred to F2** (user-set balance for now).
- [~] Add-expense/income account selector — **deferred to F2** (needs accountId on txns).

**Implemented in F1 (`feature/accounts` branch):**
- Server: `AccountType` enum + `Account` model (Prisma), migration SQL, Zod validators,
  `account.controller.js`, `/accounts` routes (GET/POST/PUT/DELETE), registered in `app.js`.
- Mobile: `features/accounts/` module — model (type→icon/color), repository, Riverpod notifier,
  Accounts screen (total header, cards, ⋯ edit/delete, empty/error states), add/edit sheet
  with numpad. Profile entry row. Shared `formatRupee` (Indian grouping) util.
- The two `[~]` items move to F2 since they require linking transactions to an account.

---

## F2 — Transfer transaction type (P0) · _Screenshot 4_

**Reference shows:** The add-transaction screen with a `INCOME | EXPENSE | TRANSFER` segmented
toggle, an Account + Category selector row, a note field, and a **calculator keypad** (we already
have this), plus a date/time footer (`Jan 21, 2021 — 2:00 PM`).

**What we build:**
- Add a `transfer` type to the entry flow. Transfer = move money between two accounts
  (From account → To account), no category, no P&L impact.
- Extend `add_expense_sheet` (or a shared entry sheet) with the 3-way segmented control.
- Date **and time** picker in the footer (currently date only — verify).

**Depends on:** F1 (needs ≥2 accounts).

**Lives in:** new `features/transfers/` module + account selector added to expense/income
sheets + `features/navigation/.../shell_screen.dart` entry-type picker.

**Acceptance:**
- [x] Transfer flow: pick From + To account (From≠To enforced), amount via numpad, optional note.
- [x] Transfer debits source, credits destination; lives in its own `Transfer` table so it's
      naturally excluded from expense/income totals.
- [x] Numpad works for all three types (expense/income/transfer).
- [x] **(F1 carryover)** Account selector now in add-expense & add-income sheets.
- [x] **(F1 carryover)** Account balances auto-adjust on create/edit/delete of expense, income,
      and transfer (atomic in a Prisma `$transaction`).
- [~] Date+time picker — **deferred**: server create endpoints use `now()` and don't accept a
      custom `createdAt`. Adding editable date/time needs a server change; tracked as a follow-up.

**Implemented in F2 (`feature/transfer` branch):**
- Server: `Transfer` model + `accountId` on Expense/Income (migration), `balance.service.js`
  (atomic balance deltas + account-ownership check), transfer controller/validator/routes,
  account-balance adjustments in expense/income controllers, registered `/transfers`.
- Mobile: `features/transfers/` module (model, repo, notifier, transfer sheet), shared
  `AccountSelector` widget, account selector in expense/income sheets, Transfer option in the
  entry picker, balance refresh via provider invalidation after every mutation.

---

## F3 — Editable Categories / CRUD (P1) · _Screenshot 8_

**Reference shows:** Two sections — **Income categories** (Business, Lottery, Salary, Sale) and
**Expense categories** (Bills, Broadband, Car, Clothing, Education…) — each row a colored icon +
name + `⋯` menu. Tagline: "Create & customize your categories, no limit."

**Current state:** `features/profile/presentation/screens/categories_screen.dart` is a **static
hardcoded list** — not editable.

**What we build:**
- Income vs Expense category sections.
- Add / rename / recolor / re-icon / delete categories (icon picker from Phosphor set).
- Persist categories; migrate existing enum-based categories to a data-driven model.
- Guard: deleting a category in use → reassign or block with a friendly message.

**Lives in:** Promote categories to its own `features/categories/` module (data + presentation),
or expand the existing profile screen + add a categories provider.

**Acceptance:**
- [ ] Separate income/expense lists.
- [ ] Full CRUD with icon + color picker.
- [ ] New categories appear in the add-transaction selectors.

---

## F4 — Records: date-grouped list + month summary (P1) · _Screenshot 1_

**Reference shows:** A `‹ January, 2021 ›` month navigator + filter icon, a 3-column summary
(`EXPENSE` red / `INCOME` green / `TOTAL`), then transactions grouped under day headers
(`Jan 03, Sunday`) with colored category icon, title, payment method chip, and signed amount.

**What we build (adapt to Expenses tab):**
- Month navigator header with prev/next + the 3-column summary strip.
- Group transactions by day with a sticky-ish day header (date + weekday).
- Each row: category icon (colored circle), title, account/payment chip, signed amount (red/green).
- Filter button (by account, category, type).

**Lives in:** `features/expenses/presentation/screens/expenses_screen.dart` (already being edited
per git status) + a reusable `transaction_tile` widget.

**Acceptance:**
- [ ] Month switching updates list + summary.
- [ ] Transactions grouped by day with weekday labels.
- [ ] Expense/Income/Total computed for the visible month.

---

## F5 — Budget planner polish (P2) · _Screenshot 3_

**Reference shows:** `‹ January, 2021 ›`, `TOTAL BUDGET` / `TOTAL SPENT`, budgeted-category
cards (Limit / Spent / Remaining + progress bar + a corner tag showing the limit). Over-limit
cards turn the bar **red** with `*Limit exceeded`. A "Not budgeted this month" section with a
`SET BUDGET` button per category.

**What we build:** Audit current `budgets_screen.dart` and add: total budget/spent header,
remaining + progress per category, **limit-exceeded** red state, and a "not budgeted yet" list
with quick set-budget action.

**Acceptance:**
- [ ] Per-category limit/spent/remaining + progress bar.
- [ ] Over-limit state is visually distinct (red + warning).
- [ ] Unbudgeted categories listed with one-tap set-budget.

---

## F6 — Analysis: overview toggle + breakdown bars (P2) · _Screenshot 2_

**Reference shows:** An `EXPENSE OVERVIEW ▾` dropdown (toggles Expense/Income), a donut with a
center label + legend, then a ranked list of categories with mini progress bars, amount, and `%`.

**Current state:** We have `category_donut_card.dart`. Mostly there.

**What we build:** Add the Expense/Income overview toggle, ensure the ranked breakdown list
(amount + percentage + bar) matches, and make donut segments tappable to filter.

**Acceptance:**
- [ ] Toggle between expense and income overview.
- [ ] Ranked category list with %, amount, progress bar.

---

## F7 — Expense Flow chart + weekly table (P2) · _Screenshot 6_

**Reference shows:** An `EXPENSE FLOW ▾` area/line chart of daily spend across a week with a
highlighted point tooltip (`Jan 07 — $95.00`), and a Sun–Sat table of daily totals below.

**Current state:** `daily_spend_chart.dart` exists. Likely needs the weekday table + tooltip.

**What we build:** Add the weekday summary table under the chart and point tooltips; reuse
`fl_chart` (already a dependency).

**Acceptance:**
- [ ] Area/line chart of daily spend for the selected range.
- [ ] Weekday table of totals; tap a point shows its value.

---

## Suggested build order

1. **F1 Accounts** (foundation)
2. **F2 Transfer** (needs F1)
3. **F3 Categories CRUD** (unblocks richer add-txn)
4. **F4 Records grouping** (already mid-edit)
5. **F6 Analysis toggle** → **F7 Expense Flow** → **F5 Budget polish**
6. Layer in **A1 icons** + **A2 images** (see `assets_plan.md`) alongside each screen.

See `assets_plan.md` for the icon-library recommendation and the image/illustration plan
(what to generate in Nano Banana and exactly where to place each one).
