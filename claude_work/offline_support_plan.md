# Offline-First Support — Plan & Learning Guide

> A complete plan to make the Expense Tracker work fully offline, written so you also
> understand *why* each piece exists. Read top to bottom the first time; later use it as
> a checklist.

---

## 1. The problem (why we're doing this)

Right now the app is **online-only**:

- The Flutter app keeps **no data on the device**. The only things stored locally are the
  auth tokens (`flutter_secure_storage`) and theme/onboarding flags (`shared_preferences`).
- Every screen calls the server through `DioClient` and holds the result in **Riverpod
  memory**. Close the app → memory is gone → next launch re-fetches everything.
- No network = blank screens. You can't even look at last month's expenses, let alone add
  a new one on a flaky connection.

**Goal:** the user can **read and write everything offline** — add/edit/delete expenses,
income, accounts, budgets, categories, transfers — and those changes **sync to the server
automatically** when the app next opens with a connection.

---

## 2. The big idea: "offline-first" (the mental model)

There are two ways to add offline support. Understanding the difference is the key concept.

### Approach A — "online-first with a cache" (what we are NOT doing)
The app still thinks of the **server as the source of truth**. It tries the network first
and falls back to a cache. This gets messy fast: every screen needs "did the network work?
no? use cache… but is the cache stale?" logic everywhere.

### Approach B — "offline-first" (what we ARE doing) ✅
We flip the relationship. The **local database on the phone becomes the source of truth
for the UI**. The server becomes a *peer we sync with in the background*.

```
   The UI NEVER talks to the network directly.
   The UI only reads/writes the local database (Drift/SQLite).

   UI  ──read/write──▶  Local DB (Drift)
                              │
                              │  (a separate background process)
                              ▼
                         Sync Engine  ◀──HTTP──▶  Server
```

Why this is better:
- The UI is **always fast** (reading from local SQLite is instant) and **always works**
  (no network needed).
- Networking lives in **one place** (the Sync Engine), not scattered across every screen.
- "Offline" stops being a special case. The app behaves *identically* online and offline;
  the only difference is whether the Sync Engine has run recently.

This is the same model used by apps like Notion, Linear, and Google Keep.

---

## 3. The three hard problems of sync (and our answers)

Any sync system has to answer three questions. Here's the theory, then our concrete choice.

### Problem 1 — "Who generates the ID?"
When you create an expense **offline**, it needs an `id` *immediately* (the UI shows it,
other records may reference it). But today the **server** generates IDs (`@default(uuid())`),
so historically the client had to wait for a network round-trip to learn the ID.

**Our answer: the client generates the ID.** We use a UUID (universally unique identifier)
package on the phone. A UUID is a 128-bit random value like
`f47ac10b-58cc-4372-a567-0e02b2c3d479` — random enough that two devices will essentially
never generate the same one. So the phone can mint a valid permanent ID with zero network,
and the server just accepts it. **No "temporary ID → real ID" remapping needed.** This is
the single most important simplification in the whole plan.

> Learning note: this works because Postgres `id` columns are already UUID strings. We
> aren't changing the *type* of the key — we're just moving *who fills it in* from server
> to client.

### Problem 2 — "How do we detect what changed since last sync?"
When the app syncs, it shouldn't re-download everything. It should ask: *"what changed
since the last time I synced?"*

**Our answer: every row carries an `updatedAt` timestamp.** The phone remembers the
timestamp of its last successful sync (`lastPulledAt`). On the next sync it asks the server
`GET /sync/pull?since=<lastPulledAt>` and the server returns only rows whose `updatedAt` is
newer. This is called a **delta pull** (delta = "the difference").

For this to work, **every syncable table needs an `updatedAt`**. Some of our tables have it
(`Account`, `Budget`, `TransactionCategory`); some don't (`Expense`, `Income`, `Transfer`).
We'll add the missing ones.

### Problem 3 — "What if the same record changed in two places?"
You edit an expense on your phone offline; meanwhile the same record changed on the server
(or another device). When you sync, which version wins? This is a **conflict**.

**Our answer: Last-Write-Wins (LWW).** Whichever version has the newer `updatedAt`
timestamp wins. This is the simplest strategy and it's *appropriate here* because this is a
**single-user app** — the same person rarely edits the same expense from two devices in the
same minute. (Bigger collaborative apps use fancier schemes like CRDTs; we don't need that
complexity.)

> Learning note: a related problem is **deletes**. If we *hard-delete* a row (remove it
> from the DB), the delta pull can't tell other devices "this was deleted" — the row just
> silently vanishes from the results. The fix is **soft delete**: instead of removing the
> row, we set a `deletedAt` timestamp. The row still shows up in the delta pull (with
> `deletedAt` set), so every device learns to hide it. We already soft-delete most tables;
> we'll fix the two that hard-delete (`Income`, `Budget`).

---

## 4. The trickiest detail: account balances

This deserves its own section because it's the easiest thing to get wrong.

**How balances work today:** the server stores `Account.balance` as a number, and every
time you add an expense it does `balance = balance - amount` (see `applyDelta()` in
`server/services/balance.service.js`, called from `expense.controller.js:61`). Income adds,
transfers move between accounts. The balance is **incrementally maintained**.

**Why that breaks with offline sync:** imagine you create 5 expenses offline, then sync. If
we replay "subtract amount" 5 times but a network hiccup causes a retry, we might subtract
twice → wrong balance. Incremental math + unreliable replay = drift and corruption.

**The fix: make balance a **derived** value, not a stored-up running total.** We compute it
fresh from the transactions:

```
balance = openingBalance
          + sum(all income into this account)
          - sum(all expenses from this account)
          + sum(all transfers into this account)
          - sum(all transfers out of this account)
```

- We add a new `openingBalance` column to `Account` (the starting balance the user typed
  when creating the account). The old `balance` column becomes a **computed cache** that we
  recalculate with a `recomputeBalance()` function after any sync.
- Recomputing is **idempotent**: running it once or five times gives the same answer. That's
  exactly the property we need for safe retries.

We do the same recompute on the **phone** (a Dart `LocalBalanceService`) so balances look
correct offline too.

> Learning note: "idempotent" = an operation you can safely repeat without changing the
> result beyond the first application. Sync systems love idempotent operations because the
> network *will* occasionally make you retry.

---

## 5. The two sync endpoints (the contract between phone and server)

All sync flows through just two new server endpoints. Keeping it to two makes the system
easy to reason about.

### `GET /sync/pull?since=<ISO timestamp>` — "give me what changed"
Returns every row for the logged-in user, across all tables, whose `updatedAt` is newer
than `since` — **including soft-deleted rows** so deletes propagate.

```jsonc
{
  "serverTime": "2026-06-21T10:30:00.000Z",   // phone saves this as the next `since`
  "changes": {
    "accounts":   [ { "id": "...", "name": "...", "deletedAt": null, ... } ],
    "categories": [ ... ],
    "expenses":   [ ... ],
    "income":     [ ... ],
    "budgets":    [ ... ],
    "transfers":  [ ... ]
  }
}
```

> Learning note — **clock skew**: the phone's clock and the server's clock are never
> perfectly in sync. If the phone used *its own* clock for the `since` cursor, it might miss
> or re-fetch records. So the **server tells the phone what time it is** (`serverTime`), and
> the phone uses that value as the cursor next time. The server's clock is the single
> authority.

### `POST /sync/push` — "here are my local changes"
The phone sends its queued offline changes as a batch, in dependency order.

```jsonc
{
  "operations": [
    { "entity": "account", "op": "upsert", "id": "<uuid>", "data": { ... }, "updatedAt": "..." },
    { "entity": "expense", "op": "upsert", "id": "<uuid>", "data": { ... }, "updatedAt": "..." },
    { "entity": "expense", "op": "delete", "id": "<uuid>", "updatedAt": "..." }
  ]
}
```

For each operation the server:
1. Checks the row belongs to this user (security — never trust the client's word on `userId`;
   take it from the JWT).
2. Applies **Last-Write-Wins**: if the stored row is *newer* than the incoming `updatedAt`,
   skip it (return `skipped-stale`).
3. Otherwise upserts (insert-or-update) or soft-deletes the row.
4. After the batch, recomputes balances for affected accounts (Section 4).

The whole batch runs inside **one database transaction** (`prisma.$transaction`) so it's
all-or-nothing. The response reports per-operation status so the phone knows which queued
items to clear vs. retry.

> Learning note — **"upsert"** = update if it exists, insert if it doesn't. Perfect for sync
> because the phone doesn't need to know whether the server has seen this record before.
>
> Learning note — **dependency order**: an expense can reference an `accountId`. So the
> account must be created on the server *before* the expense that points at it. The phone
> queues and sends parents (accounts, categories) before children (expenses, income,
> transfers).

---

## 6. Server changes (Part A)

Reason: let the client supply IDs, track per-row changes, soft-delete everywhere, and add
the two sync endpoints.

### A1. Prisma schema — `server/prisma/schema.prisma`
Apply to all syncable models (`Expense`, `Income`, `Transfer`, `Account`, `Budget`,
`TransactionCategory`):
- Keep `id String @id @default(uuid())` — the `@default` stays as a fallback, but the
  controllers will now **accept a client-supplied `id`** (Prisma already lets you pass `id`
  in `create`; we just stop stripping it).
- Add `updatedAt DateTime @updatedAt` where missing → **`Expense`, `Income`, `Transfer`**.
- Add `deletedAt DateTime?` where missing → **`Income`, `Budget`**.
- Add `openingBalance Decimal @default(0)` to **`Account`**; `balance` becomes derived.
- Add `@@index([userId, updatedAt])` to every syncable model (makes the delta pull fast).

Then create **one migration**:
```bash
cd server
npx prisma migrate dev -n offline_sync_fields
```
> ⚠️ This touches your real database (Neon/Railway). Run it yourself when ready; I won't run
> migrations for you. Review the generated SQL under `server/prisma/migrations/` first.

### A2. New sync endpoints
- `server/routes/sync.routes.js` (**new**) — mounts `GET /pull` and `POST /push` behind
  `authenticateToken`.
- `server/controllers/sync.controller.js` (**new**) — the pull + push logic from Section 5.
  Reuse the existing per-entity Zod validators for the `data` payloads.
- `server/app.js` — add `app.use("/sync", syncRouter);`.

### A3. Balance becomes derived — `server/services/balance.service.js`
- Add `recomputeBalance(tx, userId, accountId)` implementing the formula in Section 4.
- `/sync/push` calls it once per affected account at the end of the transaction (instead of
  per-operation `applyDelta`).
- Optionally refactor the existing REST controllers to call `recomputeBalance` too, so the
  online and sync paths stay consistent. (`applyDelta` can remain for now to limit blast
  radius.)

### A4. Soft-delete the two stragglers
- `server/controllers/income.controller.js` — change `tx.income.delete(...)` to
  `tx.income.update({ data: { deletedAt: new Date() } })`; add `deletedAt: null` to the
  list/read filters.
- `server/controllers/budget.controller.js` — same change for `deleteBudget`, and filter
  `deletedAt: null` in `getBudgets`.

### A5. Keep all existing REST endpoints
They still work and aren't breaking — `/sync/push` can even reuse their logic internally.
No change to existing request/response shapes.

---

## 7. Mobile changes (Part B)

### B1. New dependencies — `mobile/pubspec.yaml`
- `drift` + `drift_flutter` (+ `sqlite3_flutter_libs`, `path_provider`) — the local SQL DB.
- `uuid` — client-side ID generation (Problem 1).
- `connectivity_plus` — detect online/offline to gate sync and show a banner.
- dev: `drift_dev` (runs alongside the existing `build_runner`).

> Learning note — **why Drift (SQLite) and not Hive/Isar?** Our data is *relational*:
> expenses reference accounts and categories; balances are sums across tables. SQL is built
> for exactly this (joins, `SUM`, date-range `WHERE`). Drift gives us SQLite with
> type-safe Dart code generation that fits the existing `build_runner` setup. Hive (key-value)
> would force us to hand-roll all those relationships.

### B2. The local database — `mobile/lib/core/db/`
- `app_database.dart` (**new**) — a Drift `@DriftDatabase`. One table per entity mirroring
  the server, **plus three sync columns on every table**:
  - `updatedAt` — for LWW + delta logic.
  - `deletedAt` — local soft delete.
  - `syncStatus` — enum `synced` / `pending` / `failed`, so the UI can show "not yet synced".
- `tables/` (**new**) — `Expenses`, `Income`, `Accounts`, `Budgets`, `Categories`, `Transfers`.
- `outbox.dart` (**new**) — the **outbox table** (explained below).
- `sync_meta.dart` (**new**) — a one-row table storing `lastPulledAt`.
- A Riverpod provider `appDatabaseProvider` (singleton, like the existing `dioClientProvider`).

> Learning note — **the Outbox pattern.** When you make a change offline, you do two things
> atomically: (1) write the row to its table, and (2) append an entry to an `outbox` table
> describing the change ("upsert expense X", "delete account Y"). The Sync Engine later reads
> the outbox in order and sends it to the server. This guarantees **no change is ever lost**,
> even if the app is killed right after the edit — the intent is durably recorded on disk.

### B3. Local data sources — `mobile/lib/features/*/data/datasources/*_local_datasource.dart`
One per feature (**new**). Pure Drift reads/writes that mirror the *existing* repository
method signatures (e.g. `getExpenses(from, to, category)`), so the layers above barely
change. Date-range and category filters become SQL `WHERE` clauses.

### B4. Repositories become offline-first
Each repository (e.g. `mobile/lib/features/expenses/data/repositories/expense_repository.dart`)
changes from "call Dio" to:
- **Reads** → return from the local data source (instant, offline-safe).
- **Writes** (`create` / `update` / `delete`):
  1. Generate the `id` locally with `uuid`.
  2. Write the row to Drift with `syncStatus = pending`, `updatedAt = now` (deletes set
     `deletedAt = now`).
  3. Append an **outbox** entry.
  4. Recompute the affected account's balance locally (`LocalBalanceService`).
  5. Fire-and-forget kick the Sync Engine (no-op if offline).

The **method signatures stay the same** (`createExpense({amount, ...})`), so the Riverpod
providers in `expense_provider.dart` and the screens need little to no change. The Dio calls
move *out* of repositories and *into* the Sync Engine.

### B5. The Sync Engine — `mobile/lib/core/sync/sync_engine.dart` (**new**)
A Riverpod service with one guarded `sync()` method (a mutex prevents two syncs running at
once):
1. **Push:** read the outbox in order → batch into `POST /sync/push` → on success clear
   those rows / mark `synced`; on `skipped-stale` adopt the server's copy; on error bump an
   `attempts` counter and keep the entry for retry.
2. **Pull:** `GET /sync/pull?since=lastPulledAt` → upsert returned rows into Drift (applying
   soft deletes) → save the new `serverTime` as `lastPulledAt`.
3. **Recompute** balances for touched accounts.
- Exposes a `syncStatusProvider` (idle / syncing / error + "last synced" time) for the UI.

### B6. When does sync run? (the trigger)
Per your choice: **on app launch and when the app returns to the foreground.**
- On launch: after auth is restored in `auth_provider.dart`.
- On foreground: an `AppLifecycleListener` in the root widget.
- `connectivity_plus` gates attempts (don't try while offline) and makes a future
  "sync the instant the connection returns" trigger a one-line addition.

### B7. First run / login bootstrap
On first login (or fresh install with an existing token), do a **full pull** (`since` =
epoch / very old date) to fill the local DB before showing the home screen, behind a
one-time "Setting things up…" state. Pull **categories first** (expenses/budgets reference
them).

### B8. Logout must wipe the local DB
The local DB holds **one user's** data. On logout (in `auth_repository.dart`) call
`appDatabase.wipe()` and clear the outbox. If the outbox isn't empty, **warn the user**
that unsynced changes will be lost before proceeding.

---

## 8. What the user actually sees (the features)

- **Everything works offline.** Add/edit/delete expenses, income, accounts, budgets,
  categories, transfers with no connection. From the user's point of view nothing changes —
  it just stops failing when offline.
- **Offline banner.** A subtle "You're offline — changes will sync later" bar when
  disconnected.
- **Sync status.** In the home header / settings: "Last synced 2m ago", a spinner while
  syncing, tappable to **force a sync now**.
- **Pending indicator.** A small dot/badge on records whose `syncStatus == pending`.
- **Conflicts are invisible (v1).** With Last-Write-Wins we silently adopt the winning
  version — no scary "resolve conflict" dialog.

---

## 9. Build order (phased — each phase ships independently)

1. **Server foundation** — schema migration, soft-delete fixes, `recomputeBalance`,
   `/sync/pull` + `/sync/push`. Verify with curl/Postman before touching the app.
2. **Mobile DB layer** — Drift tables, outbox, codegen, local data sources. No UI change yet.
3. **Offline reads** — point repository reads at Drift; add the bootstrap full-pull.
4. **Offline writes + Sync Engine** — client UUIDs, outbox, push/pull, local balance
   recompute, launch/foreground triggers.
5. **UX polish** — offline banner, sync status, pending badges, logout wipe.

Doing them in this order means you always have a working app, and you learn one concept per
phase rather than all at once.

---

## 10. Files at a glance

**Server**
- `server/prisma/schema.prisma` — `updatedAt` / `deletedAt` / `openingBalance` + indexes.
- `server/routes/sync.routes.js`, `server/controllers/sync.controller.js` — **new**.
- `server/services/balance.service.js` — add `recomputeBalance`.
- `server/controllers/income.controller.js`, `budget.controller.js` — hard → soft delete.
- `server/app.js` — mount `/sync`.

**Mobile**
- `mobile/pubspec.yaml` — deps.
- `mobile/lib/core/db/` — `app_database.dart`, `tables/`, `outbox.dart`, `sync_meta.dart` — **new**.
- `mobile/lib/core/sync/sync_engine.dart`, `local_balance_service.dart` — **new**.
- `mobile/lib/features/*/data/datasources/*_local_datasource.dart` — **new** per feature.
- `mobile/lib/features/*/data/repositories/*_repository.dart` — refactor to offline-first.
- `mobile/lib/features/auth/.../auth_repository.dart`, `auth_provider.dart` — bootstrap pull,
  wipe on logout, launch sync.
- Root widget (`main.dart` / router shell) — lifecycle trigger + offline banner.

---

## 11. How we'll verify it works

**Server (after Phase 1):**
- `npx prisma migrate dev` runs clean; `npx prisma studio` shows the new columns.
- `POST /sync/push` with a client-generated UUID expense → the row appears with *that* id;
  the account balance recomputes correctly.
- `GET /sync/pull?since=<old timestamp>` → returns the new row, and a later soft-deleted one
  with `deletedAt` set.
- Stale push: send an old `updatedAt` → response says `skipped-stale`, DB unchanged.

**Mobile (per phase):**
- `dart run build_runner build` generates Drift + Riverpod code with no errors.
- **Airplane-mode test:** turn off network → add/edit/delete an expense, add an account, set
  a budget → all appear instantly, balances correct, offline banner shows.
- Turn network back on → foreground the app → outbox drains → status shows "synced" → confirm
  on the server via `GET /sync/pull` or Prisma Studio.
- **Restart while offline:** kill and relaunch with no network → data is still there (proves
  Drift persisted it, not just memory).
- **Last-Write-Wins:** edit the same record on two devices offline, sync both → the newer
  edit wins on both.
- **Logout:** log out → local DB wiped → log in as another user → only their data appears.

---

## 12. Risks & gotchas to keep in mind

- **Balance correctness** is the #1 risk — solved by making balance *derived* and
  *idempotent* (`recomputeBalance`) instead of incremental.
- **Clock skew** — always use the server's `serverTime` as the pull cursor, never the phone's
  clock.
- **Dependency order** — push accounts/categories before the expenses/income/transfers that
  reference them.
- **Validation mismatch** — the server's `ExpenseSchema` requires `description.min(5)` on
  create but `max(255)` on update. Mirror these rules in the client so an offline-created row
  doesn't get rejected when it finally pushes.
- **Migration safety** — review the generated SQL before applying to the production DB;
  back-fill `openingBalance` from the current `balance` so existing accounts don't reset to 0.
