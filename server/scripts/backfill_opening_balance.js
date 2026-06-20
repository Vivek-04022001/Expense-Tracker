/**
 * One-time backfill — run ONCE, right after applying the `offline_sync_fields`
 * migration that adds Account.openingBalance.
 *
 * Existing accounts carry a correct (incrementally maintained) `balance`, but the
 * new `openingBalance` column defaults to 0. Since balance is now *derived*
 * (openingBalance + activity), we must seed openingBalance so a future
 * recomputeBalance() reproduces the current balance instead of resetting it:
 *
 *     openingBalance = balance - activity
 *     activity       = Σincome - Σexpense + ΣtransfersIn - ΣtransfersOut  (non-deleted)
 *
 * Usage:  node scripts/backfill_opening_balance.js
 */
import { prisma } from "../src/db.js";

const num = (v) => parseFloat(v ?? 0);

async function main() {
  const accounts = await prisma.account.findMany({
    select: { id: true, balance: true },
  });

  for (const a of accounts) {
    const [income, expense, transfersIn, transfersOut] = await Promise.all([
      prisma.income.aggregate({
        _sum: { amount: true },
        where: { accountId: a.id, deletedAt: null },
      }),
      prisma.expense.aggregate({
        _sum: { amount: true },
        where: { accountId: a.id, deletedAt: null },
      }),
      prisma.transfer.aggregate({
        _sum: { amount: true },
        where: { toAccountId: a.id, deletedAt: null },
      }),
      prisma.transfer.aggregate({
        _sum: { amount: true },
        where: { fromAccountId: a.id, deletedAt: null },
      }),
    ]);

    const activity =
      num(income._sum.amount) -
      num(expense._sum.amount) +
      num(transfersIn._sum.amount) -
      num(transfersOut._sum.amount);

    const openingBalance = num(a.balance) - activity;

    await prisma.account.update({
      where: { id: a.id },
      data: { openingBalance },
    });
  }

  console.log(`Backfilled openingBalance for ${accounts.length} account(s).`);
}

main()
  .catch((err) => {
    console.error("Backfill failed:", err);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
