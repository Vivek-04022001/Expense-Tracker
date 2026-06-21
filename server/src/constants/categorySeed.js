// Built-in categories seeded for every user as system rows.
// `key` is a stable identifier that mirrors the legacy Category / IncomeType enum
// values so charts and budget aggregation keep working while custom categories
// are layered on top.
//
// Keep this list in sync with the migration that backfills existing users
// (prisma/migrations/20260620000000_add_category_table/migration.sql) and with the
// mobile phosphor icon registry (mobile/lib/features/categories/data/category_icons.dart).

export const BUILTIN_EXPENSE_CATEGORIES = [
  { key: "food_and_drink", name: "Food & Drink", icon: "forkKnife", color: "#FF6B4A", sortOrder: 0 },
  { key: "transport", name: "Transport", icon: "car", color: "#5B8DEF", sortOrder: 1 },
  { key: "bills_and_utilities", name: "Bills & Utilities", icon: "receipt", color: "#FFB020", sortOrder: 2 },
  { key: "shopping", name: "Shopping", icon: "bag", color: "#B66BFF", sortOrder: 3 },
  { key: "health", name: "Health", icon: "heartbeat", color: "#00C48C", sortOrder: 4 },
  { key: "entertainment", name: "Entertainment", icon: "ticket", color: "#FF4D9D", sortOrder: 5 },
  { key: "education", name: "Education", icon: "bookOpen", color: "#7AC74F", sortOrder: 6 },
  { key: "other", name: "Other", icon: "dotsThree", color: "#8A90A0", sortOrder: 7 },
];

export const BUILTIN_INCOME_CATEGORIES = [
  { key: "salary", name: "Salary", icon: "briefcase", color: "#00C48C", sortOrder: 0 },
  { key: "freelance", name: "Freelance", icon: "laptop", color: "#5B8DEF", sortOrder: 1 },
  { key: "investment", name: "Investment", icon: "trendUp", color: "#B66BFF", sortOrder: 2 },
  { key: "reward", name: "Reward", icon: "gift", color: "#FFB020", sortOrder: 3 },
  { key: "other", name: "Other", icon: "dotsThree", color: "#8A90A0", sortOrder: 4 },
];

// Flat list of seed rows (without userId) used for inserting built-ins for a user.
export const BUILTIN_CATEGORIES = [
  ...BUILTIN_EXPENSE_CATEGORIES.map((c) => ({ ...c, kind: "expense" })),
  ...BUILTIN_INCOME_CATEGORIES.map((c) => ({ ...c, kind: "income" })),
];

/**
 * Seed the built-in system categories for a user if they have none yet.
 * Idempotent: skips when system rows already exist for the user.
 * Accepts a prisma client or a $transaction client.
 */
export const seedBuiltinCategories = async (client, userId) => {
  const existing = await client.transactionCategory.count({
    where: { userId, isSystem: true },
  });
  if (existing > 0) return;

  await client.transactionCategory.createMany({
    data: BUILTIN_CATEGORIES.map((c) => ({
      userId,
      name: c.name,
      kind: c.kind,
      icon: c.icon,
      color: c.color,
      key: c.key,
      isSystem: true,
      sortOrder: c.sortOrder,
    })),
  });
};
