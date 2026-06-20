# Paisa — Icons & Images Plan

Two goals from the brief:

1. **Great-looking, consistent icons** (not generic Material defaults).
2. **Human-feel imagery** — where to place illustrations/photos so the app doesn't read as
   "AI-made". Every image below includes a suggested **Nano Banana prompt** + exact placement.

_Last updated: 2026-06-19_

---

## A1 — Icon system

### Recommendation: **keep Phosphor as the base, add Lucide for line work**

You already depend on `phosphor_flutter` — that's a strong, modern choice (consistent stroke,
both `regular` and `fill` weights, huge set). **Keep it as the primary family.** Don't mix three
icon styles; that's the #1 tell of an "AI-made" app.

| Library                   | Package                         | Use for                                 | Why                                                    |
| ------------------------- | ------------------------------- | --------------------------------------- | ------------------------------------------------------ |
| **Phosphor** (primary)    | `phosphor_flutter` ✅ installed | Nav, actions, category glyphs           | Already in use; 1,200+ icons; fill+regular weights     |
| **Lucide** (optional)     | `lucide_icons`                  | Thin-line accents, empty-state line art | Cleaner hairline look if Phosphor feels heavy in spots |
| **Category brand glyphs** | local SVG via `flutter_svg`     | Account types (Visa/UPI/cash)           | Brand marks Phosphor can't provide                     |

**Rules to keep it looking hand-crafted:**

- One weight per context: `fill` for active nav + category circles, `regular` for inline/secondary.
- Category icons live on a **colored circle** (reuse `AppColors.forCategory`) — matches the
  reference's colored-circle look but in our palette.
- Don't auto-assign random icons to categories; curate the mapping (extend `category_mapper.dart`).
- Consistent corner radius + circle size across Records, Analysis, Budgets, Categories, Accounts.

**Action items:**

- [ ] Build a `CategoryAvatar` shared widget (circle + Phosphor icon + category color) and use it
      everywhere a category is shown.
- [ ] Curate Phosphor icons for the income categories (Salary→`wallet`, Business→`briefcase`,
      Lottery→`ticket`, Sale→`tag`) and expense ones (Bills→`receipt`, Broadband→`wifi-high`,
      Car→`car`, Clothing→`t-shirt`, Education→`graduation-cap`…).
- [ ] If adding Lucide, restrict it to empty-state line art only.

---

## A2 — Image / illustration plan (for Nano Banana)

**Style guide for ALL generated images** (paste into every prompt for consistency — this is what
makes them feel like one product, not stock):

> Flat vector illustration, soft rounded shapes, warm but modern palette built around deep blue
> `#0B5FFF` and mint green `#00C48C` with off-white background, subtle grain/texture, gentle long
> shadows, friendly and optimistic, Indian context (rupee ₹, Indian people/clothing/streets where
> people appear), no text in the image, consistent line weight, 2:1 safe margins, transparent or
> off-white background.

Generate at **3x** (e.g. 1024px+) and export PNG; drop into `mobile/assets/images/` (already a
declared asset folder in `pubspec.yaml`) and add an `assets/illustrations/` subfolder.

### Where each image goes

| #   | Image                                      | Placement                                             | Why it adds "human" feel                  | Nano Banana prompt seed                                                                                                                                                                                      |
| --- | ------------------------------------------ | ----------------------------------------------------- | ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| I1  | **Onboarding hero (×3)**                   | `onboarding_screen.dart` — one per slide              | First impression; sets tone               | "A young Indian person happily tracking money on a phone, coins and ₹ notes floating, flat vector" / "Person planning a monthly budget with charts" / "Person reaching a savings goal, piggy bank, confetti" |
| I2  | **Empty: no transactions**                 | Expenses/Records empty state                          | Turns a dead screen into a friendly nudge | "Friendly empty wallet with a small plant growing out of it, hinting at fresh start, flat vector"                                                                                                            |
| I3  | **Empty: no accounts**                     | Accounts screen (F1) empty state                      | Guides first action                       | "A neat row of cards, a coin jar and a wallet floating, inviting to add, flat vector"                                                                                                                        |
| I4  | **Empty: no budget set**                   | Budgets screen empty state                            | Encourages setup                          | "A calm person setting a target on a dial, balanced scale of ₹ coins, flat vector"                                                                                                                           |
| I5  | **Savings goal art**                       | Savings screen header / goal cards                    | Emotional, motivating                     | "A small rocket / piggy bank climbing stairs toward a flag labelled with a goal, flat vector"                                                                                                                |
| I6  | **Success / celebration**                  | Reuse with `success_overlay.dart` after save/transfer | Delight on completion                     | "Minimal confetti burst with a checkmark coin, flat vector, transparent bg"                                                                                                                                  |
| I7  | **Profile header banner**                  | Top of `profile_screen.dart`                          | Warmth, personality                       | "Soft abstract gradient with floating ₹ coins and tiny financial icons, wide banner, flat vector"                                                                                                            |
| I8  | **SMS import explainer**                   | `sms_import_screen.dart` / `sms_preview` intro        | Explains a novel feature visually         | "A phone receiving a bank SMS that turns into a neat expense card, arrow flow, flat vector"                                                                                                                  |
| I9  | **Insights/Analysis empty**                | Analysis tab before data                              | Avoids blank charts                       | "A magnifying glass over a friendly donut chart, flat vector"                                                                                                                                                |
| I10 | **Account-type icons (set)**               | Account cards (card/cash/wallet/savings/investment)   | Cohesive, branded                         | "A matching set of 5 flat icons: credit card, cash notes, wallet, piggy-bank savings, growth-chart investment, same style and palette"                                                                       |
| I11 | **App store / dark-theme hero** (optional) | Marketing + splash                                    | Polish                                    | "App dashboard mockup on a phone at night, glowing charts, cozy, flat vector"                                                                                                                                |

### Where NOT to add images

- Dense data screens (Records list, budget cards): keep them clean — icons only. Images there
  create clutter and slow scrolling.

### Implementation notes

- Add `assets/illustrations/` to `pubspec.yaml` `flutter.assets`.
- Build a reusable `EmptyState` widget: illustration + title + subtitle + optional CTA. Use it for
  I2–I4, I9 so empty states are consistent.
- Cache/optimize PNGs (compress) — illustrations can be large; consider WebP.
- For dark theme: either generate dark variants of I1–I9 or design illustrations on transparent
  backgrounds that read on both themes (preferred — fewer assets).

---

## Quick checklist

- [ ] Confirm Phosphor stays primary; decide on Lucide yes/no.
- [ ] Build `CategoryAvatar` + `EmptyState` shared widgets first (reused everywhere).
- [ ] Generate I1–I3 + I6 first (highest visible impact: onboarding, empty records/accounts, success).
- [ ] Register `assets/illustrations/` in pubspec.
- [ ] Keep one style guide for every Nano Banana generation.
