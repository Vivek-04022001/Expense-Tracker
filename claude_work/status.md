# Paisa — Work Tracker

> Single source of truth for what we're building, in what order, and where it stands.
> Update the **Status** column as we move. Detailed specs live in `features.md`.

_Last updated: 2026-06-19_

## Legend
`📋 Planned` · `🔨 In progress` · `🔍 In review` · `✅ Done` · `⏸ On hold` · `❌ Dropped`

## Context

The 8 reference screenshots come from a competitor app ("Money Manager / MyMoney") with a
cream/vintage aesthetic. We are using them as **feature inspiration only** — every feature is
re-implemented in Paisa's existing modern design system (see `mobile/lib/core/theme/`).
We are **not** copying the cream/yellow look. The goal is feature parity + a polished, human feel.

## Current app (baseline) — already built

| Area | State |
|------|-------|
| Bottom nav | Floating pill, 4 tabs: Home / Expenses / Stats / Profile + center FAB |
| Add expense | Calculator numpad sheet (income + expense) |
| Insights | Donut chart, daily spend chart, top merchants, budget list |
| Budgets | Budgets screen exists |
| Categories | **Static demo list only** (not editable) |
| Accounts | **Does not exist** |
| Transfer txn type | **Does not exist** (income/expense only) |
| SMS import | Built (see memory: project_sms_import) |
| Dark theme | Supported |

## Roadmap

| # | Feature | Screens | Priority | Status |
|---|---------|---------|----------|--------|
| F1 | Accounts (wallets/cards/cash) | 7 | P0 | ✅ Done (merged to dev) |
| F2 | Transfer transaction type | 4 | P0 | ✅ Done (merged to dev) |
| F3 | Editable Categories (CRUD) | 8 | P1 | ✅ Done (merged to dev) |
| F4 | Records: date-grouped list + month summary header | 1 | P1 | ✅ Done (merged to dev) |
| F5 | Budget planner polish (limit-exceeded states) | 3 | P2 | 📋 Planned |
| F6 | Analysis: income/expense overview toggle + breakdown bars | 2 | P2 | 📋 Planned |
| F7 | Expense Flow chart + weekly table | 6 | P2 | 📋 Planned |
| A1 | Icon system upgrade (see assets_plan.md) | all | P1 | 📋 Planned |
| A2 | Human-feel illustrations/images (see assets_plan.md) | all | P2 | 📋 Planned |

## Decisions log

- 2026-06-19 — Keep Paisa's modern theme; screenshots are feature refs, not visual refs.
- 2026-06-19 — Accounts (F1) is the foundation; Transfer (F2) depends on it. Build F1 first.
- 2026-06-19 — F1 scope = **full-stack** (Prisma model + API + Flutter), per user.
- 2026-06-19 — Committed 3 pre-existing WIP fixes to `dev` before branching (env URL, provider
  invalidation, root-navigator sheets). Then branched `feature/accounts`.
- 2026-06-19 — F1 builds Accounts as a **standalone** CRUD + balances unit. Linking
  expense/income to an `accountId` is deferred to **F2 (Transfer)**, where account linkage is
  required anyway — keeps F1 small and reviewable.
- 2026-06-19 — Workflow per feature: branch → build → **user approval** → merge to `dev`.
- 2026-06-20 — F3 Categories = **full table migration**. New `TransactionCategory` table
  (renamed from `Category` to avoid colliding with the existing `Category` enum). Additive &
  non-destructive: legacy `Category`/`IncomeType` enum columns are **kept** so the SMS
  classifier, insights charts, and budget aggregation keep working unchanged.
- 2026-06-20 — Built-ins seeded as **system rows** (`isSystem=true`) with stable `key` values
  matching the legacy enum values (8 expense + 5 income). Custom categories layer on top
  (`key=null`). System rows are editable (name/icon/color) but **not deletable**; `kind`/`key`
  are immutable. New users seeded on register; existing users seeded by the migration backfill
  and lazily on first `GET /categories`.
- 2026-06-20 — Transaction sheets now send BOTH the legacy enum (derived from the selected
  category's `key`, custom → `other`) AND the new `categoryId`. Keeps charts/SMS intact while
  linking the richer category.

## Branch / merge workflow

| Feature | Branch | Merged to dev? |
|---------|--------|----------------|
| F1 Accounts | `feature/accounts` | ✅ merged 2026-06-19 (--no-ff) |
| F2 Transfer | `feature/transfer` | ✅ merged 2026-06-19 (--no-ff) |
| F3 Categories CRUD | `feature/categories` | ✅ merged 2026-06-20 (--no-ff) |
| F4 Records | `feature/records` | ✅ merged 2026-06-20 (--no-ff) |

## ✅ F1 done

- Migration applied to Neon (confirmed by user 2026-06-19).
- `feature/accounts` merged into `dev`.

## ⚠️ Action needed before F2 fully works

- [ ] **Apply F2 DB migration to Neon.** File:
  `server/prisma/migrations/20260619010000_add_transfer_and_account_links/migration.sql`
  (adds `Transfer` table + `accountId` columns on Expense/Income). Apply with
  `cd server && npx prisma migrate deploy`. The `/transfers` API and account linkage will
  error until this is applied.

## ⚠️ Action needed before F3 fully works

- [ ] **Apply F3 DB migration to Neon.** File:
  `server/prisma/migrations/20260620000000_add_category_table/migration.sql`
  (creates `CategoryKind` enum + `TransactionCategory` table, adds `categoryId` to
  Expense/Income/Budget, seeds built-ins per existing user, backfills `categoryId` from the
  legacy enum columns). Apply with `cd server && npx prisma migrate deploy`. The `/categories`
  API and category linkage will error until this is applied. Uses `gen_random_uuid()`
  (available natively on Neon/Postgres 13+).

## Open questions

- [x] Does the server/API already model accounts? → No. Built new `Account` model + `/accounts` API.
- [ ] Should category CRUD sync to server or stay local? (decide at F3)
- [ ] Confirm currency is ₹ (INR) everywhere (reference shows $). Added shared `formatRupee` util.
