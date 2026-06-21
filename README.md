# Paisa — Expense Tracker

![Paisa logo](mobile/assets/images/app_logo.png)

**Paisa** is a full-stack, offline-first personal finance app for India-first
everyday money tracking. It pairs a **Flutter** mobile client with a
**Node.js / Express + Prisma / PostgreSQL** backend, connected by a custom
delta-sync protocol so the app stays fully usable with or without a network
connection.

> This document is intentionally detailed — it is meant to be a single, complete
> reference for the project's features, data model, architecture, and APIs.

---

## Table of Contents

1. [What It Does](#what-it-does)
2. [Feature Catalogue](#feature-catalogue)
3. [Architecture Overview](#architecture-overview)
4. [Offline-First Sync Engine](#offline-first-sync-engine)
5. [Tech Stack](#tech-stack)
6. [Repository Structure](#repository-structure)
7. [Database / Data Model](#database--data-model)
8. [Backend API Reference](#backend-api-reference)
9. [Mobile App Structure](#mobile-app-structure)
10. [Getting Started](#getting-started)
11. [Environment Variables](#environment-variables)
12. [Design & UX Notes](#design--ux-notes)
13. [Glossary](#glossary)

---

## What It Does

- **Track expenses, income, transfers, and accounts** with per-transaction
  category, payment method, account linkage, and descriptions.
- **Manage multiple accounts** (bank, cash, wallet, card, savings, investment)
  with **automatically derived balances** computed from opening balance plus all
  activity.
- **Set monthly budgets per category** and track spend-vs-limit progress.
- **Customizable categories** — every user is seeded with built-in expense and
  income categories (each with a Phosphor icon + color) and can add their own.
- **Dashboards & statistics** — monthly spend, savings rate, today/this-week
  totals, recent transactions, budget progress, and spending-trend charts.
- **Offline-first** — all reads and writes hit a local SQLite database first;
  changes are queued and synced to the server in the background.
- **Daily reminders** — schedule one or two local notifications per day to nudge
  expense logging.
- **Secure auth** — phone + password login with JWT access/refresh tokens,
  bcrypt-hashed passwords, and the ability to revoke refresh tokens on logout.
- **Light & dark themes**, onboarding flow, and India-first currency (₹)
  formatting.

---

## Feature Catalogue

### Authentication & Profile
- Register with **name, phone, password**; phone is the unique login identifier.
- Login issues a short-lived **access token** and a 7-day **refresh token**
  (persisted server-side in a `RefreshToken` table).
- Refresh endpoint mints new access tokens; logout **revokes** the refresh token.
- Passwords hashed with **bcrypt**.
- Profile name can be updated (`PATCH /auth/me`); phone is immutable.
- New users are automatically **seeded with built-in categories** on register.

### Accounts
- CRUD for financial accounts with types: `card`, `cash`, `wallet`, `bank`,
  `savings`, `investment`, `other`.
- Each account has a user-entered **`openingBalance`** and a **derived
  `balance`**:
  `balance = openingBalance + income − expenses + transfers in − transfers out`
  (non-deleted rows only).
- Balance recomputation is **idempotent**, so replaying synced offline changes
  never double-counts (see [`balance.service.js`](server/services/balance.service.js)).
- Optional per-account color.

### Expenses
- Create / read / update / soft-delete expenses.
- Fields: `amount`, `category`, `paymentMethod` (`upi`, `bank_transfer`, `cash`,
  `other`), optional `description`, linked `account`, and linked custom
  `category`.
- Expense **summary** endpoint for aggregations.
- Dedicated detail screen and bottom-sheet add flow with a built-in calculator
  numpad (theme-aware for dark mode).

### Income
- Create / read / update / soft-delete income.
- Income types: `salary`, `freelance`, `investment`, `reward`, `other`.
- Linked to accounts and custom categories; increases account balance.

### Transfers
- Move money **between two accounts** in a single record.
- Decreases the source account balance, increases the destination.
- Create / read / soft-delete.

### Budgets
- One budget per **(category, month, year)** — enforced by a composite unique
  constraint.
- Upsert semantics (`PUT /budgets`); budget **status** endpoint reports
  spend-vs-limit progress.
- Surfaced on the home dashboard as a budget-progress card.

### Categories
- Built-in **system categories** for both expenses and income, each with a
  stable `key`, Phosphor `icon`, and `color`.
- Users can **create, update, and delete custom categories** (`kind` =
  `expense` | `income`), with `sortOrder` and soft delete.
- Built-in keys mirror the legacy enum values so charts, budgets, and
  aggregations stay consistent.

### Savings & Statistics
- **Savings summary** endpoint and screen (income vs. expenses).
- Statistics screen with spending-overview and trend cards (charts via
  `fl_chart`).
- Home dashboard widgets: greeting header, monthly-spend card, savings-rate
  card, today/this-week row, budget progress, and recent transactions.

### Reminders (Local Notifications)
- Schedule a **primary** daily reminder and an optional **second** daily
  reminder at user-chosen times.
- Recurring local notifications via `flutter_local_notifications` +
  `timezone`; tapping a reminder deep-links into the add-expense flow.
- Contextual OS permission request, "send test notification" action, and
  per-reminder cancellation.

### Offline-First Sync
- Full local **SQLite (Drift)** mirror of all entities.
- **Outbox** queue of pending mutations + **delta pull** cursor.
- Last-Write-Wins conflict resolution, soft deletes that propagate, and
  connectivity-aware background sync.

---

## Architecture Overview

```
┌─────────────────────────────┐         ┌──────────────────────────────┐
│        Flutter App           │         │      Express API (Node)       │
│  ┌───────────────────────┐  │  HTTPS  │  ┌────────────────────────┐  │
│  │ Riverpod UI / Screens  │  │ (Dio +  │  │ Routes → Controllers    │  │
│  └──────────┬────────────┘  │  JWT)   │  │  → Services             │  │
│             │                │ ◄─────► │  └──────────┬─────────────┘  │
│  ┌──────────▼────────────┐  │         │             │                 │
│  │ Repositories           │  │         │  ┌──────────▼─────────────┐  │
│  └──────────┬────────────┘  │         │  │ Prisma Client          │  │
│  ┌──────────▼────────────┐  │         │  └──────────┬─────────────┘  │
│  │ Drift (SQLite) + Outbox│  │         │             │                 │
│  └──────────┬────────────┘  │         │  ┌──────────▼─────────────┐  │
│  ┌──────────▼────────────┐  │         │  │ PostgreSQL (Neon)      │  │
│  │ Sync Engine (push/pull)│◄─┼─────────┼─►│  via WebSocket adapter │  │
│  └───────────────────────┘  │ /sync   │  └────────────────────────┘  │
└─────────────────────────────┘         └──────────────────────────────┘
```

- The mobile app follows a **feature-first, layered** structure
  (`data` → `repositories` → `presentation/providers` → UI), with shared
  infrastructure in `core/`.
- The server is a thin **route → controller → service** stack over Prisma,
  with Zod validators and JWT middleware.
- Connectivity to PostgreSQL uses the **Neon serverless adapter** over
  WebSockets.

---

## Offline-First Sync Engine

The app is **local-first**: the UI reads and writes the on-device SQLite (Drift)
database, and a background sync engine reconciles with the server.

**Client side** (`mobile/lib/core/sync/`, `core/db/`):
- Every syncable row carries `createdAt`, `updatedAt`, `deletedAt`, and a
  `syncStatus` (`synced` | `pending` | `failed`).
- Local mutations are appended to a durable **Outbox** table (one row per change)
  and to the entity table optimistically.
- IDs are **client-generated UUIDs**, so the same id works locally and on the
  server with no remapping.
- A sync cycle is **push then pull**, guarded by a mutex so concurrent callers
  share one in-flight run. `syncQuietly()` / `pullQuietly()` swallow transient
  offline errors.
- Connectivity is observed via `connectivity_plus` to trigger syncs when back
  online.

**Server side** (`server/controllers/sync.controller.js`):
- `GET /sync/pull?since=<ISO>` returns **every row changed after `since`**
  (including soft-deleted rows) plus the authoritative `serverTime`, which the
  client stores as its next cursor.
- `POST /sync/push` accepts a batch of `{ entity, op, id, data, updatedAt }`
  operations (`op` = `upsert` | `delete`) and applies them in a single
  transaction.
- **Conflict policy: Last-Write-Wins** — an incoming change is `skipped-stale`
  when the stored row's `updatedAt` is newer.
- **Ownership** is enforced server-side; a client-supplied `userId` is never
  trusted.
- Deletes are **soft** (`deletedAt`) so they propagate through the delta pull.
- After a push, affected **account balances are recomputed from scratch**
  (idempotent) rather than incrementally adjusted.

Synced entities: `account`, `category`, `expense`, `income`, `transfer`,
`budget`.

---

## Tech Stack

### Mobile (Flutter)
| Concern | Package |
|---|---|
| State management | `flutter_riverpod`, `riverpod_annotation` |
| Navigation | `go_router` |
| HTTP | `dio` |
| Local DB (offline-first) | `drift`, `sqlite3_flutter_libs`, `path_provider` |
| Client UUIDs | `uuid` |
| Connectivity | `connectivity_plus` |
| Secure token storage | `flutter_secure_storage` |
| Preferences | `shared_preferences` |
| Charts | `fl_chart` |
| Animations | `flutter_animate`, `animated_text_kit` |
| Icons | `phosphor_flutter` |
| Notifications | `flutter_local_notifications`, `timezone`, `flutter_timezone` |
| Formatting / Fonts | `intl`, `google_fonts` |

### Server (Node.js)
| Concern | Tooling |
|---|---|
| Runtime / framework | Node.js (ESM), Express 5 |
| ORM | Prisma 7 (`@prisma/client`) |
| Database | PostgreSQL (Neon serverless via `@prisma/adapter-neon` + `ws`) |
| Auth | `jsonwebtoken` (JWT), `bcrypt` |
| Validation | `zod` |
| Middleware | `cors`, JSON body parsing |
| Dev | `nodemon` |

---

## Repository Structure

```
expense_tracker/
├── mobile/                      # Flutter client (branded "Paisa")
│   ├── lib/
│   │   ├── core/                # cross-cutting infrastructure
│   │   │   ├── db/              # Drift schema (tables.dart) + generated DB
│   │   │   ├── sync/            # sync engine, outbox, sync API, connectivity
│   │   │   ├── network/         # Dio client
│   │   │   ├── router/          # GoRouter + transitions
│   │   │   ├── notifications/   # local notification service
│   │   │   ├── theme/           # colors, spacing, typography, theme provider
│   │   │   ├── balance/         # local balance service
│   │   │   ├── animation/       # shared motion helpers
│   │   │   └── utils/           # category mapper, expense visuals
│   │   ├── features/            # feature-first modules (see below)
│   │   └── shared/              # shared widgets + utils (currency, etc.)
│   ├── assets/                  # images, illustrations
│   └── pubspec.yaml
│
└── server/                      # Express + Prisma API
    ├── app.js                   # express app + route mounting
    ├── index.js                 # server bootstrap
    ├── routes/                  # one router per resource
    ├── controllers/             # request handlers
    ├── services/                # balance & category domain logic
    ├── middleware/              # auth (JWT) + zod validate
    ├── src/
    │   ├── db.js                # Prisma client (Neon adapter)
    │   ├── validators/          # Zod schemas
    │   ├── constants/           # built-in category seed
    │   └── generated/prisma/    # generated Prisma client
    ├── prisma/
    │   ├── schema.prisma        # data model
    │   └── migrations/
    └── scripts/                 # e.g. backfill_opening_balance.js
```

Mobile feature modules (each typically with `data/`, `repositories/`, and
`presentation/{providers,screens,sheets,widgets}`):
`auth`, `accounts`, `expenses`, `income`, `transfers`, `budgets`, `categories`,
`savings`, `statistics`, `home`, `navigation`, `onboarding`, `profile`,
`reminders`.

---

## Database / Data Model

PostgreSQL via Prisma (`server/prisma/schema.prisma`). All financial models use
**soft deletes** (`deletedAt`) and `updatedAt` for delta sync.

### Enums
- **Category**: `food_and_drink`, `transport`, `bills_and_utilities`,
  `shopping`, `health`, `entertainment`, `education`, `other`
- **IncomeType**: `salary`, `freelance`, `investment`, `reward`, `other`
- **PaymentMethod**: `upi`, `bank_transfer`, `cash`, `other`
- **AccountType**: `card`, `cash`, `wallet`, `bank`, `savings`, `investment`,
  `other`
- **CategoryKind**: `expense`, `income`

### Models

**User** — `id`, `name`, `phone` (unique), `passwordHash`, `createdAt`; relations
to expenses, incomes, budgets, accounts, transfers, categories, refresh tokens.

**TransactionCategory** — user-scoped category. `name`, `kind`, `icon`, `color`,
nullable `key` (stable id for seeded built-ins), `isSystem`, `sortOrder`,
timestamps + `deletedAt`. Indexed by `userId` and `(userId, updatedAt)`.

**Account** — `name`, `type` (AccountType), `openingBalance` (user-entered),
`balance` (derived), optional `color`, timestamps + `deletedAt`.

**Expense** — `amount`, `category` (enum, default `other`), `paymentMethod`,
optional `description`, optional `accountId` and `categoryId` (custom category
ref), timestamps + `deletedAt`.

**Income** — `amount`, `incomeType`, optional `description`, optional `accountId`
and `categoryId`, timestamps + `deletedAt`.

**Transfer** — `amount`, optional `description`, `fromAccountId`, `toAccountId`,
timestamps + `deletedAt`.

**Budget** — `limitAmount`, `category` (enum), optional `categoryId`, `month`,
`year`. **Unique on `(userId, category, month, year)`**.

**RefreshToken** — `token` (unique), `isRevoked`, `userId`, `createdAt`,
`expiredAt`.

> **Derived balances:** `Account.balance` is never trusted from the client. The
> server recomputes it as `openingBalance + Σincome − Σexpenses + ΣtransfersIn −
> ΣtransfersOut` over non-deleted rows after every relevant change.

---

## Backend API Reference

Base URL: `http://localhost:3000` (configurable via `PORT`).
All routes except auth/health require a **Bearer access token** in the
`Authorization` header.

### Health
| Method | Path | Description |
|---|---|---|
| GET | `/health` | Service health check |

### Auth (`/auth`)
| Method | Path | Description |
|---|---|---|
| POST | `/auth/register` | Register (name, phone, password); seeds built-in categories |
| POST | `/auth/login` | Login → `{ accessToken, refreshToken }` |
| POST | `/auth/refresh-token` | Exchange refresh token → new access token |
| POST | `/auth/logout` | Revoke a refresh token |
| PATCH | `/auth/me` | Update profile name (auth required) |

### Expenses (`/expenses`)
| Method | Path | Description |
|---|---|---|
| GET | `/expenses` | List expenses |
| POST | `/expenses` | Create expense |
| PUT | `/expenses/:id` | Update expense |
| DELETE | `/expenses/:id` | Soft-delete expense |
| GET | `/expenses/summary` | Expense aggregations |

### Income (`/income`)
| Method | Path | Description |
|---|---|---|
| GET | `/income` | List income |
| POST | `/income` | Create income |
| PATCH | `/income/:id` | Update income |
| DELETE | `/income/:id` | Soft-delete income |

### Accounts (`/accounts`)
| Method | Path | Description |
|---|---|---|
| GET | `/accounts` | List accounts |
| POST | `/accounts` | Create account (Zod-validated) |
| PUT | `/accounts/:id` | Update account (Zod-validated) |
| DELETE | `/accounts/:id` | Soft-delete account |

### Transfers (`/transfers`)
| Method | Path | Description |
|---|---|---|
| GET | `/transfers` | List transfers |
| POST | `/transfers` | Create transfer (Zod-validated) |
| DELETE | `/transfers/:id` | Soft-delete transfer |

### Budgets (`/budgets`)
| Method | Path | Description |
|---|---|---|
| GET | `/budgets` | List budgets |
| PUT | `/budgets` | Upsert budget (Zod-validated) |
| DELETE | `/budgets/:id` | Soft-delete budget |
| GET | `/budgets/:id/status` | Spend-vs-limit status |

### Categories (`/categories`)
| Method | Path | Description |
|---|---|---|
| GET | `/categories` | List categories |
| POST | `/categories` | Create custom category (Zod-validated) |
| PATCH | `/categories/:id` | Update category (Zod-validated) |
| DELETE | `/categories/:id` | Soft-delete category |

### Savings (`/savings`)
| Method | Path | Description |
|---|---|---|
| GET | `/savings/summary` | Income-vs-expense savings summary |

### Sync (`/sync`)
| Method | Path | Description |
|---|---|---|
| GET | `/sync/pull?since=<ISO>` | Delta pull of all rows changed since cursor |
| POST | `/sync/push` | Apply a batch of upsert/delete operations |

---

## Mobile App Structure

- **State**: Riverpod providers per feature (`*_provider.dart`, code-gen
  `*.g.dart`). Auth and router providers are `keepAlive`.
- **Routing**: `go_router` with a `StatefulShellRoute` (Home / Expenses /
  Statistics / Profile tabs) plus pushed routes for Budgets and Savings.
  Redirect logic gates on auth + onboarding state (`/splash`, `/login`,
  `/register`, `/onboarding` are public).
- **Local DB**: Drift schema in `core/db/tables.dart`; every entity table mixes
  in `_SyncColumns`. Plus an `Outbox` queue and single-row `SyncMeta` cursor.
- **Networking**: `dio` client with JWT injection; sync API in
  `core/sync/sync_api.dart`.
- **Theming**: light/dark themes, custom colors/typography/spacing,
  `phosphor_flutter` icons, `google_fonts`.
- **Currency**: India-first ₹ formatting (`shared/utils/currency.dart`).

---

## Getting Started

### 1. Backend

```bash
cd server
npm install
```

Create `server/.env` (see [Environment Variables](#environment-variables)), then:

```bash
# generate Prisma client + apply migrations
npx prisma generate
npx prisma migrate deploy   # or `prisma migrate dev` in development

npm run dev                 # nodemon (hot reload)
# or
npm start                   # production
```

The API listens on `0.0.0.0:$PORT` (default `3000`).

### 2. Mobile App

```bash
cd mobile
flutter pub get

# regenerate Riverpod/Drift code if you change providers or DB tables
dart run build_runner build --delete-conflicting-outputs

flutter run
```

Point the app at your backend via the base URL in
`mobile/lib/core/constants/api_constants.dart`.

---

## Environment Variables

`server/.env`:

```env
PORT=3000
DATABASE_URL=            # PostgreSQL / Neon pooled connection string
DIRECT_URL=             # direct (non-pooled) connection for migrations
ACCESS_TOKEN_SECRET=    # JWT signing secret (access)
ACCESS_TOKEN_EXPIRY=    # e.g. 15m
REFRESH_TOKEN_SECRET=   # JWT signing secret (refresh)
REFRESH_TOKEN_EXPIRY=   # e.g. 7d
```

---

## Design & UX Notes

- **Onboarding** shows once; after a user authenticates it is permanently marked
  seen.
- **Floating navbar**: bottom sheets use the root navigator; detail screens
  root-push; tab screens leave ~100px bottom clearance to avoid overlap.
- **Calculator numpad** in the add-expense sheet uses theme-aware colors for
  dark mode.
- **Notifications** request OS permission contextually (only when the user
  enables a reminder).
- **Soft deletes everywhere** keep history intact and let deletes sync cleanly.

---

## Glossary

- **Outbox** — durable on-device queue of local mutations awaiting push.
- **Delta pull** — fetching only rows changed since the last cursor.
- **Last-Write-Wins (LWW)** — conflict rule: newest `updatedAt` wins.
- **Derived balance** — account balance recomputed from activity, not stored
  from the client.
- **System category** — built-in, seeded category (`isSystem = true`) with a
  stable `key`.

---

*Mobile app is branded **Paisa** (`mobile/pubspec.yaml`). Backend is a standalone
Express/Prisma service. Both share the data model defined in
`server/prisma/schema.prisma` and the sync contract in
`server/controllers/sync.controller.js`.*
