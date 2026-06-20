# Fixes — UX / Bug Backlog

Tracking list for reported issues. Each entry has the **report**, the **root cause** found in code,
the **affected files**, and the **proposed fix**.

---

## 1. Onboarding screens show every time — what is the logic? ✅ DONE

**Resolution:** The flag already gated onboarding on *unauthenticated + not-yet-seen*. To guarantee it
appears only once ever, `app_router.dart` now calls `markSeen()` (via `Future.microtask`) the moment a
user is `AuthAuthenticated`. So after a user logs in even once, onboarding never reappears (e.g. after a
future logout). First-launch persistence stays in `SharedPreferences` (`onboarding_seen`).

---

### Original analysis

**Report:** Onboarding appears repeatedly. Does it appear every time for a logged-in user?

**Answer / current logic:**
- The "seen" flag is a single boolean `onboarding_seen` persisted in `SharedPreferences`.
  See `lib/features/onboarding/presentation/providers/onboarding_provider.dart`.
- It is set to `true` only when the user taps **Skip** or finishes the last page
  (`_finish()` → `markSeen()`) in `lib/features/onboarding/presentation/screens/onboarding_screen.dart`.
- Routing is decided in `lib/core/router/app_router.dart` `redirect`:
  - `AuthAuthenticated` → always redirected to `/home`. **A logged-in user never sees onboarding.**
  - `AuthUnauthenticated` **and** `!onboardingSeen` → `/onboarding`.
  - `AuthUnauthenticated` **and** `onboardingSeen` → `/login`.

**So:** onboarding is gated on *unauthenticated + not-yet-seen*, not on login. A logged-in user
should never see it. If it shows every launch, the real cause is one of:
  1. `markSeen()` runs but the flag isn't persisting (verify `onboarding_seen` is actually written/read).
  2. The session isn't being restored on cold start, so the app lands in `AuthUnauthenticated`
     before auth resolves — combined with `onboardingSeen == false` that routes to onboarding.

**To verify:** log the value returned by `OnboardingNotifier.build()` and confirm `markSeen()` persists
across a kill/relaunch.

**Proposed fix:** confirm the flag persists; if the desired behaviour is "only the very first install ever,"
the current design is correct once persistence is verified. (No code change until the repro is confirmed.)

---

## 2. Remove the SMS auto-import feature completely ✅ DONE

**Resolution:**
- Deleted `lib/features/sms_import/` and `lib/features/profile/presentation/screens/sms_import_screen.dart`.
- Removed the "SMS auto-import" row + import from `profile_screen.dart`.
- Removed the "SMS import success" notification (and its Activity group) from `notifications_screen.dart`.
- Rewrote SMS-themed copy in onboarding (pages 1–2 now about manual tracking & organizing),
  help & support FAQs, and the privacy policy (dropped the "SMS Access" section).
- Updated the legacy-enum comments in `add_expense_sheet.dart` / `categories_screen.dart` (charts/reports
  still rely on the enum; SMS no longer mentioned).
- Deleted SMS tests under `test/features/sms_import/` and the unused `sms_import_explainer.png` asset.
- Updated `pubspec.yaml` description. `flutter analyze` is clean (no SMS references remain).

---

### Original plan

**Report:** Remove auto-import-SMS from settings, onboarding, everywhere.

**Affected files (feature module):**
- `lib/features/sms_import/` (whole directory: models, parsers, providers, screens, services)
- `lib/features/profile/presentation/screens/sms_import_screen.dart`
- Profile entry point: `lib/features/profile/presentation/screens/profile_screen.dart:159` ("SMS auto-import" row → `SmsImportScreen`)
- `lib/features/expenses/presentation/sheets/add_expense_sheet.dart` — comment notes the "SMS classifier" still relies on the legacy category enum (decouple before deleting)
- Mentions in `onboarding_screen.dart`, `help_support_screen.dart`, `notifications_screen.dart`, `privacy_policy_screen.dart`
- Memory note: `project_sms_import.md` (design doc) — mark feature removed
- Also check `pubspec.yaml` for SMS-reading plugins and Android `AndroidManifest.xml` for `READ_SMS`/`RECEIVE_SMS` permissions

**Proposed fix:**
1. Remove the "SMS auto-import" `ProfileRow` from `profile_screen.dart` and drop the import.
2. Delete `lib/features/sms_import/` and `sms_import_screen.dart`.
3. Strip SMS copy from onboarding, help/support, notifications, privacy-policy screens.
4. Keep the legacy category enum populated in `add_expense_sheet.dart` but remove the SMS-classifier comment/coupling.
5. Remove SMS plugin deps from `pubspec.yaml` and SMS permissions from the Android manifest.
6. Run `flutter analyze` to catch dangling imports.

---

## 3. Home loading → shimmer ✅ DONE

**Resolution:** Replaced the per-card `CircularProgressIndicator`s with an animated shimmer. Added a
reusable `Shimmer` + `ShimmerBox` widget at `lib/shared/widgets/shimmer.dart` (self-contained, no new
dependency — uses a sweeping `ShaderMask` gradient). Applied shimmer placeholders to the loading states of
`monthly_spend_card`, `today_this_week_row`, `recent_transactions_list`, and `savings_rate_card`.

> Note: the original request below (one full-screen loader gating all data) was reinterpreted as
> per-section shimmer per the follow-up. Kept for reference.

---

### Original idea: single full-screen loader until all home data is ready

**Report:** Home screen shows loading; instead, after login show the logo/loader and hold until the
home (and other) data is fetched, then navigate in.

**Root cause:** Each home widget independently watches its own provider and renders its own
`CircularProgressIndicator`, so the screen pops in piecemeal:
- `lib/features/home/presentation/screens/home_screen.dart` composes the widgets directly.
- e.g. `monthly_spend_card.dart` watches `expenseSummaryProvider` + `currentMonthIncomesProvider` and shows its own spinner; other cards (`savings_rate_card`, `today_this_week_row`, `recent_transactions_list`, `insight_banner`) do the same.
- The splash (`splash_screen.dart`) only waits on auth, not on home data.

**Proposed fix:** Introduce a combined "home bootstrap" provider that awaits all the home providers
(expense summary, incomes, savings, recent transactions, insights). Gate `HomeScreen` (or the splash/a
shared loader) on that single provider — show the logo + one loader while it resolves, then render the
fully-populated screen. Remove the per-card spinners (or keep them as a fallback only).

---

## 4. Expense bottom sheet — no visual separation between categories and payment methods ✅ DONE

**Resolution:** Added small uppercase section labels (`_FieldLabel`) above each group in
`add_expense_sheet.dart` — **CATEGORY**, **ACCOUNT**, and **PAYMENT METHOD** — with consistent spacing,
so the category chips and the payment segmented control read as clearly separate sections.

---

### Original analysis

**Report:** In the add-expense sheet, "Food & Drinks…" (categories) and the payment-method tabs blend
together; users get confused about which is which.

**Root cause:** In `lib/features/expenses/presentation/sheets/add_expense_sheet.dart` the sections stack
with no headings between them: `CategorySelector` (chips) → `AccountSelector` → merchant/date row →
payment-method segmented tabs (Cash / UPI / Bank Transfer). None of the groups has a label, so the
category chips and payment tabs read as one continuous control.

**Proposed fix:** Add small section labels/dividers above each group ("Category", "Account",
"Payment method"), and/or visually distinguish the payment segmented control from the category chips
(different container styling). Group related controls with consistent spacing.

---

## 5. Account-type illustration is too small (new-account sheet) ✅ DONE

**Resolution:** Increased the illustration height from `56` to `120` in `add_account_sheet.dart`.

---

### Original analysis

**Report:** In Accounts → new-account bottom sheet, the image above the Card/Cash/Wallet options is too small.

**Root cause:** `lib/features/accounts/presentation/sheets/add_account_sheet.dart:176` renders
`assets/illustrations/account_type_icon.png` at a fixed `height: 56` with `BoxFit.contain`, so it appears small.

**Proposed fix:** Increase the height (e.g. 96–120) or rethink the visual — possibly show the illustration
per-selected-type, or replace with proper per-type icons on the chips themselves. Confirm the asset's
intrinsic resolution supports the larger size.

---

## 6. Categories screen — bottom nav bar covers the bottom of the screen ✅ DONE

**Resolution:** `_push` in `profile_screen.dart` now uses `Navigator.of(context, rootNavigator: true)`,
so Categories (and the other Profile detail screens) are pushed above the shell's bottom nav bar instead
of being overlapped by it. The add (+) FAB and bottom content are now fully visible.

---

### Original analysis

**Report:** Settings → Categories: the bottom nav bar hides the bottom of the screen, so the button can't be seen.

**Root cause:** Categories is opened with `_push(const CategoriesScreen())` from the Profile tab
(`profile_screen.dart:141`), and `_push` uses `Navigator.of(context)` (`profile_screen.dart:88`). Because
Profile lives inside the `StatefulShellRoute` branch, the page is pushed onto the **nested** branch navigator,
so the shell's persistent bottom nav bar stays on top and overlaps the screen's lower content
(the FAB / add button). The list only reserves `bottom: 96` padding, which isn't a reliable offset for the nav bar.

**Proposed fix (pick one):**
- Push Categories on the **root** navigator (`Navigator.of(context, rootNavigator: true)`) so it covers the bottom nav, **or**
- Make Categories a top-level GoRoute outside the shell, **or**
- If it must stay inside the shell, pad the body/FAB by the nav-bar height (`MediaQuery` + nav height) so nothing is occluded.

---

## 7. "Clear all data" → screen goes completely black ✅ DONE (removed)

**Resolution:** Per follow-up, the "Clear all data" row and its `_confirmClearData` dialog were removed
entirely from the Profile/Settings screen (`profile_screen.dart`). The black-screen path is gone with it.

---

### Original analysis

**Report:** Tapping Clear all data on the Settings/Profile screen turns the screen completely black.

**Root cause:** In `lib/features/profile/presentation/screens/profile_screen.dart` `_confirmClearData()`,
**both** the "Cancel" and "Clear" buttons currently only call `Navigator.pop(context)` — there is no actual
data-clear or sign-out logic wired up. The reported black screen therefore points to either:
- a stale/older clear path, or
- a clear-and-logout flow that, once implemented, leaves the router with no valid destination (empty/black frame)
  while auth transitions.

**Proposed fix:**
1. Implement the real clear action (wipe local stores / SharedPreferences / DB + sign out) behind the "Clear" button.
2. After clearing, explicitly route to a valid screen (e.g. `/login` or `/onboarding`) so the redirect logic
   in `app_router.dart` always has a destination — preventing the blank frame.
3. Guard async gaps with `mounted` checks before navigating.

---

### Suggested order
2 (remove SMS) and 5/6 (quick UI fixes) are low-risk and self-contained. 3 (loader) and 7 (clear data) touch
app-level state/routing and need testing. 1 is investigate-then-decide. 4 is pure UI polish.
