# Premium Animation System + Insights Screen Redesign

Status: **All phases complete ✅** (Phase 0 → 4, plus Phase 3 navigation). `flutter analyze lib` → 0 errors / 0 warnings.
Packages: `flutter_animate: ^4.5.0` (already present), `animated_text_kit: ^4.3.0` (installed)

## Done summary
- **Phase 0** — `lib/core/animation/`: `app_motion.dart` (tokens), `animated_count.dart`, `entrance.dart`, `pressable_scale.dart`. Reduced-motion aware.
- **Phase 1** — sliding-pill mode toggle, pull-to-refresh, entrance cascade, press feedback (Insights).
- **Phase 2** — count-up on Total spend / donut center / income total; delta pill lands after.
- **Phase 4** — gradient hero band w/ sparkline, sliver layout + sticky toggle, animated donut (pop + dim siblings), budget bars grow from baseline, per-card identity icons (`card_title_icon.dart`), redesigned empty state (typewriter + CTA). Deleted dead `total_spend_card.dart` + `IncomeTotalCard`.
- **Phase 3** — `lib/core/router/transitions.dart`: `slideFadePage` (go_router detail routes), `slideFadeRoute` (Navigator pushes app-wide), `FadeBranchContainer` (tab fade-through). Staggered month-picker sheet rows.

⚠️ Not yet run on a device/emulator — verified via static analysis only.

---

## Design read (what we're working with)

- **Font:** Inter (single family, weights 400–800) via `google_fonts`. Tabular figures for all ₹ amounts. No display face — the personality has to come from *weight contrast + motion*, not a second typeface.
- **Palette:** Blue `#0B5FFF` (primary), green `#00C48C` (success/income), fixed per-category colors. Light + dark themed via `context.bgBase` etc.
- **Surfaces:** 16px-radius cards, soft `0.04` black shadow, on a near-white / near-black base.
- **Current motion:** almost none. `flutter_animate` is only used in 3 files (history, shell, success overlay). `fl_chart` does its own implicit chart tweens. Insights screen is fully static — cards just snap in.

**Design thesis for the motion layer:** *money in motion.* Numbers count up, bars grow from their baseline, the donut sweeps in. The app should feel like it's tallying your money in front of you, not just printing a static report. Restraint rule: **one orchestrated entrance per screen + quiet micro-feedback on touch.** No looping/ambient animation (it reads as AI-generated and drains battery).

---

## Phase 0 — Motion foundation (shared, build first)

Create `lib/core/animation/` so motion is consistent and tunable from one place, not hand-rolled per widget.

1. **`app_motion.dart`** — durations & curves tokens:
   - `fast = 180ms`, `base = 320ms`, `slow = 520ms`
   - `entrance = Curves.easeOutCubic`, `emphasized = Curves.easeOutBack` (used sparingly), `spring` for press.
   - `staggerStep = 60ms` for list/card cascades.
2. **`animated_count.dart`** — a `TweenAnimationBuilder<double>` wrapper that counts a ₹ value from 0 (or from previous value) to target, reusing the existing `_fmtRupee` formatting + tabular figures. This is the single most "premium" win and gets reused across home + insights.
3. **`entrance.dart`** — small extension helpers: `.fadeSlideIn({delay})` and `.staggeredColumn()` wrapping `flutter_animate` so every screen cascades identically.
4. Respect **reduced motion**: helpers check `MediaQuery.disableAnimations` and fall back to instant/opacity-only. Quality floor, non-negotiable.

---

## Phase 1 — Micro-animations (whole app, low risk)

| Where | Animation | How |
|---|---|---|
| All tappable cards / list rows | Press scale-down to `0.98` + settle | small `_PressableScale` wrapper (GestureDetector + AnimatedScale), `spring` curve |
| Mode toggle (Expenses/Income) | Already `AnimatedContainer` — add a sliding pill thumb behind the labels instead of recoloring each segment | `Stack` + `AnimatedAlign` |
| Add/FAB + nav | icon micro-bounce on tap | `flutter_animate` `.scale()` one-shot on tap |
| Success overlay | already animated — leave as-is |
| Pull-to-refresh on Insights | add `RefreshIndicator` re-running entrance cascade | wire to provider refresh |

## Phase 2 — Text animations (targeted, premium)

`animated_text_kit` + the count-up builder. **Used in exactly 3 hero spots** — over-using text animation is the fastest way to look cheap.

1. **Insights "Total spend"** → count-up from 0 on month-load; the % delta pill fades+slides in *after* the number lands (`base` delay).
2. **Donut center total** → count-up synced with the pie sweep so the number and the ring fill together.
3. **Home monthly-spend hero** (optional, same `AnimatedCount` widget) for consistency.
4. **Empty states** → keep the headline but add a one-line `TypewriterAnimatedText` *only* on first appearance, not on every rebuild (guard with a flag).

## Phase 3 — Navigation / transition animations

1. **Tab switches (shell):** wrap the body in `AnimatedSwitcher` with a fade-through (fade + 4px slide), so Insights/Home/History don't hard-cut.
2. **Detail push routes** (`go_router`): add a shared `CustomTransitionPage` — fade + subtle upward slide (16px), `entrance` curve. Centralize in `app_router.dart`.
3. **Bottom sheets** (add expense, month picker): they already use `useRootNavigator` per the navbar-overlap rule — add staggered fade-in of their inner rows so the sheet content cascades after the sheet slides up.

---

## Phase 4 — Insights screen redesign (the "dull" fix)

The screen is a flat vertical stack of 6 same-looking white cards. Problems: no hierarchy, no hero moment, the most important number (total spend) looks identical to a list row, charts appear without life.

**Redesign moves:**

1. **Hero band, not a card.** Replace the small `TotalSpendCard` with a full-bleed gradient hero at the top of the scroll: large count-up total, delta pill, and a 7-day sparkline (mini `fl_chart` line) showing trend. Gradient derived from primary (expense) / success (income) so the hero reskins with the mode toggle. This becomes the screen's signature.
2. **Sticky segmented control.** The Expenses/Income toggle pins under the header (`SliverPersistentHeader`) so it stays reachable while scrolling — convert the `ListView` to `CustomScrollView`/slivers.
3. **Entrance choreography.** Cards cascade in with `staggerStep` (Phase 0). Donut sweeps (`startDegreeOffset` animated from -90 with a one-shot tween), bars grow from baseline, legend rows fade in after the donut settles.
4. **Tighter card hierarchy.** Give section cards a small eyebrow label + icon (e.g. "BREAKDOWN", "DAILY", "BUDGETS") so they stop looking interchangeable. Numbers stay tabular and dominant; supporting labels go `textTertiary`.
5. **Donut polish.** Animate the selected-segment radius pop on touch (already partly there — add an `AnimatedScale`/implicit tween instead of instant setState), dim non-selected segments slightly when one is touched.
6. **Budget bars.** Animate fill width on first load; color shifts to `danger` past 100% with a brief pulse.
7. **Empty state.** Keep illustration, add the Phase-2 typewriter line + a primary CTA ("Add your first expense") instead of a dead-end message.

No new colors or fonts are introduced — the redesign is hierarchy + motion + one gradient hero, all derived from existing tokens.

---

## Suggested build order (each step compiles & is reviewable)

1. Phase 0 foundation (`core/animation/`) — no visible change yet.
2. Phase 1 micro-interactions app-wide (cheap, high feel-per-line).
3. Phase 2 count-up on Insights total + donut center.
4. Phase 4 Insights redesign (hero band, slivers, choreography) — the big one.
5. Phase 3 navigation transitions last (touches router + shell, broadest blast radius).

## Risks / notes

- Converting Insights `ListView` → slivers touches the whole screen build — do it on its own commit.
- `animated_text_kit` typewriter must be guarded so it doesn't replay on every `setState`/month change (it will look glitchy otherwise).
- Keep all entrance animations **one-shot** (not `onPlay: loop`) and reduced-motion aware.
- Dark mode: gradient hero needs a dark variant — verify contrast on `darkBgBase`.
