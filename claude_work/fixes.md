# Paisa — Fixes & Polish Backlog

Bugs, rough edges, and tech-debt to clean up alongside the feature work in `features.md`.
Not feature requests — those go in `features.md`.

_Last updated: 2026-06-19_

## Legend
`📋 Open` · `🔨 Fixing` · `✅ Fixed` · `❓ Needs repro`

## Open items

| # | Area | Issue | Severity | Status |
|---|------|-------|----------|--------|
| X1 | Categories | `categories_screen.dart` is a static hardcoded list — not wired to real data | High | 📋 |
| X2 | Data model | No `Account` concept; expenses/income have no account linkage | High | 📋 |
| X3 | Add txn | No Transfer type; no time picker (date only?) — verify | Med | 📋 |
| X4 | Currency | Reference uses `$`; confirm app renders `₹`/INR consistently | Med | ❓ |
| X5 | Theme | Verify dark theme covers every new screen we add | Med | 📋 |
| X6 | Uncommitted | 3 modified files on `dev` (api_constants, expense_provider, expenses_screen) — review/commit before new work | Low | 📋 |

## Polish / "doesn't feel AI-made" checklist

These are the small touches that separate a template from a real product. Apply per screen.

- [ ] **Empty states** — every list (accounts, categories, records, budgets) needs a friendly
      empty state with an illustration + one-line copy + a clear CTA (see `assets_plan.md` A2).
- [ ] **Micro-interactions** — tap feedback, number count-up on balances, chart entrance
      animations (we already depend on `flutter_animate`).
- [ ] **Real, human copy** — avoid generic "No data". Use voice: "Nothing logged yet — add your
      first expense 👇". India-first tone.
- [ ] **Consistent iconography** — one icon family, consistent weight/style (see `assets_plan.md` A1).
- [ ] **Color discipline** — reuse `AppColors` category palette; don't introduce ad-hoc colors.
- [ ] **Currency & number formatting** — `intl` grouping (₹1,23,456 Indian grouping), 2 decimals.
- [ ] **Haptics** — light haptic on save / delete / tab switch.
- [ ] **Loading skeletons** instead of spinners on list screens.
- [ ] **Success overlays** — already have `success_overlay.dart`; reuse for transfers/accounts.

## Verify-before-building

- [ ] Read current `budgets_screen.dart` to see how much of F5 already exists.
- [ ] Read `daily_spend_chart.dart` for F7 gap.
- [ ] Confirm whether `server/` models accounts/categories (affects F1/F3 local-vs-sync decision).
