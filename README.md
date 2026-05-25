# Expense Tracker

![Paisa logo](mobile/assets/images/app_logo.png)

Full-stack personal finance app with a Flutter mobile client and a Node.js/Express backend.

The mobile app, branded as **Paisa**, focuses on everyday expense tracking for India-first use cases, including SMS-based import on Android. The backend provides authentication, budgets, expenses, income tracking, and savings summaries through a Prisma/PostgreSQL API.

## What It Does

- Track expenses, income, and monthly budgets.
- View summaries for spending, savings, and budget progress.
- Authenticate users with access and refresh tokens.
- Import SMS-based transaction data on supported Android devices.
- Sync app data through a REST API backed by PostgreSQL and Prisma.

## Project Structure

- `mobile/` - Flutter app built with Riverpod, GoRouter, Dio, and Fl Chart.
- `server/` - Express API with Prisma, JWT auth, and PostgreSQL.

## Tech Stack

- Mobile: Flutter, Riverpod, GoRouter, Dio, Shared Preferences, Secure Storage, Flutter Animate.
- Server: Node.js, Express, Prisma, PostgreSQL, JWT, Zod, CORS.

## Getting Started

### 1. Backend

```bash
cd server
npm install
```

Create a `.env` file in `server/` with:

```env
PORT=3000
DATABASE_URL=
DIRECT_URL=
ACCESS_TOKEN_SECRET=
ACCESS_TOKEN_EXPIRY=
REFRESH_TOKEN_SECRET=
REFRESH_TOKEN_EXPIRY=
```

Then run the API:

```bash
npm run dev
```

If you change the Prisma schema, regenerate the client and apply migrations as needed.

### 2. Mobile App

```bash
cd mobile
flutter pub get
flutter run
```

Android is required for SMS import features. The rest of the app works as a standard Flutter client.

## API Overview

Base route: `http://localhost:3000`

- `GET /` - Health check
- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/refresh-token`
- `POST /auth/logout`
- `GET /expenses`
- `POST /expenses`
- `PUT /expenses/:id`
- `DELETE /expenses/:id`
- `GET /expenses/summary`
- `GET /budgets`
- `PUT /budgets`
- `DELETE /budgets/:id`
- `GET /budgets/:id/status`
- `GET /income`
- `POST /income`
- `PATCH /income/:id`
- `DELETE /income/:id`
- `GET /savings/summary`

Most routes require a Bearer access token in the `Authorization` header.

## Notes

- Prisma uses the schema in `server/prisma/schema.prisma` and generates the client into `server/src/generated/prisma`.
- The Flutter app stores local preferences with `SharedPreferences` and secure tokens with `flutter_secure_storage`.
- Expense records support soft deletion through `deletedAt`.
