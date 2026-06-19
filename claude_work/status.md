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
| F1 | Accounts (wallets/cards/cash) | 7 | P0 | 📋 Planned |
| F2 | Transfer transaction type | 4 | P0 | 📋 Planned |
| F3 | Editable Categories (CRUD) | 8 | P1 | 📋 Planned |
| F4 | Records: date-grouped list + month summary header | 1 | P1 | 📋 Planned |
| F5 | Budget planner polish (limit-exceeded states) | 3 | P2 | 📋 Planned |
| F6 | Analysis: income/expense overview toggle + breakdown bars | 2 | P2 | 📋 Planned |
| F7 | Expense Flow chart + weekly table | 6 | P2 | 📋 Planned |
| A1 | Icon system upgrade (see assets_plan.md) | all | P1 | 📋 Planned |
| A2 | Human-feel illustrations/images (see assets_plan.md) | all | P2 | 📋 Planned |

## Decisions log

- 2026-06-19 — Keep Paisa's modern theme; screenshots are feature refs, not visual refs.
- 2026-06-19 — Accounts (F1) is the foundation; Transfer (F2) depends on it. Build F1 first.

## Open questions

- [ ] Does the server/API already model accounts, or is this client-side only first?
- [ ] Should category CRUD sync to server or stay local?
- [ ] Confirm currency is ₹ (INR) everywhere (reference shows $).
