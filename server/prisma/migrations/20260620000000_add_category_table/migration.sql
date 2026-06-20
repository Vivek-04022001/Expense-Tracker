-- F3 Editable Categories: additive, non-destructive migration.
-- Adds a TransactionCategory table, links Expense/Income/Budget to it via an
-- optional categoryId, seeds built-in system categories for every existing user,
-- and backfills the new FK from the legacy enum columns (which are kept as-is).

-- CreateEnum
CREATE TYPE "CategoryKind" AS ENUM ('expense', 'income');

-- CreateTable
CREATE TABLE "TransactionCategory" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "kind" "CategoryKind" NOT NULL,
    "icon" TEXT NOT NULL,
    "color" TEXT NOT NULL,
    "key" TEXT,
    "isSystem" BOOLEAN NOT NULL DEFAULT false,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "TransactionCategory_pkey" PRIMARY KEY ("id")
);

-- AlterTable
ALTER TABLE "Expense" ADD COLUMN "categoryId" TEXT;
ALTER TABLE "Income" ADD COLUMN "categoryId" TEXT;
ALTER TABLE "Budget" ADD COLUMN "categoryId" TEXT;

-- CreateIndex
CREATE INDEX "TransactionCategory_userId_idx" ON "TransactionCategory"("userId");
CREATE INDEX "Expense_categoryId_idx" ON "Expense"("categoryId");
CREATE INDEX "Income_categoryId_idx" ON "Income"("categoryId");
CREATE INDEX "Budget_categoryId_idx" ON "Budget"("categoryId");

-- AddForeignKey
ALTER TABLE "TransactionCategory" ADD CONSTRAINT "TransactionCategory_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Expense" ADD CONSTRAINT "Expense_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "TransactionCategory"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "Income" ADD CONSTRAINT "Income_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "TransactionCategory"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "Budget" ADD CONSTRAINT "Budget_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "TransactionCategory"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Seed built-in (system) categories for every existing user.
-- Keep in sync with server/src/constants/categorySeed.js.
INSERT INTO "TransactionCategory"
    ("id", "userId", "name", "kind", "icon", "color", "key", "isSystem", "sortOrder", "createdAt", "updatedAt")
SELECT
    gen_random_uuid(),
    u."id",
    b."name",
    b."kind"::"CategoryKind",
    b."icon",
    b."color",
    b."key",
    true,
    b."sortOrder",
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM "User" u
CROSS JOIN (VALUES
    ('food_and_drink',      'Food & Drink',      'expense', 'forkKnife',  '#FF6B4A', 0),
    ('transport',           'Transport',         'expense', 'car',        '#5B8DEF', 1),
    ('bills_and_utilities', 'Bills & Utilities', 'expense', 'receipt',    '#FFB020', 2),
    ('shopping',            'Shopping',          'expense', 'bag',        '#B66BFF', 3),
    ('health',              'Health',            'expense', 'heartbeat',  '#00C48C', 4),
    ('entertainment',       'Entertainment',     'expense', 'ticket',     '#FF4D9D', 5),
    ('education',           'Education',         'expense', 'bookOpen',   '#7AC74F', 6),
    ('other',               'Other',             'expense', 'dotsThree',  '#8A90A0', 7),
    ('salary',              'Salary',            'income',  'briefcase',  '#00C48C', 0),
    ('freelance',           'Freelance',         'income',  'laptop',     '#5B8DEF', 1),
    ('investment',          'Investment',        'income',  'trendUp',    '#B66BFF', 2),
    ('reward',              'Reward',            'income',  'gift',       '#FFB020', 3),
    ('other',               'Other',             'income',  'dotsThree',  '#8A90A0', 4)
) AS b("key", "name", "kind", "icon", "color", "sortOrder");

-- Backfill the new FK from the legacy enum columns.
UPDATE "Expense" e
SET "categoryId" = tc."id"
FROM "TransactionCategory" tc
WHERE tc."userId" = e."userId"
  AND tc."isSystem" = true
  AND tc."kind" = 'expense'
  AND tc."key" = e."category"::text;

UPDATE "Income" i
SET "categoryId" = tc."id"
FROM "TransactionCategory" tc
WHERE tc."userId" = i."userId"
  AND tc."isSystem" = true
  AND tc."kind" = 'income'
  AND tc."key" = i."incomeType"::text;

UPDATE "Budget" bg
SET "categoryId" = tc."id"
FROM "TransactionCategory" tc
WHERE tc."userId" = bg."userId"
  AND tc."isSystem" = true
  AND tc."kind" = 'expense'
  AND tc."key" = bg."category"::text;
