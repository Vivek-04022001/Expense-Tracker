/**
 * Account balance helpers. All functions take a Prisma transaction client (`tx`)
 * so balance updates stay atomic with the transaction that triggers them.
 *
 * Sign convention (effect on the linked account balance):
 *   expense  -> decreases balance
 *   income   -> increases balance
 *   transfer -> decreases `from`, increases `to`
 */

/** Adds `delta` to an account's balance. No-op when accountId is null. */
export async function applyDelta(tx, accountId, delta) {
  if (!accountId || !delta) return;
  await tx.account.update({
    where: { id: accountId },
    data: { balance: { increment: delta } },
  });
}

/**
 * Recomputes an account's `balance` from scratch and writes it back.
 *
 *   balance = openingBalance
 *             + sum(income into account)
 *             - sum(expenses from account)
 *             + sum(transfers into account)
 *             - sum(transfers out of account)
 *
 * Only non-deleted rows count. This is idempotent — running it once or many
 * times yields the same result — which makes it safe to call after replaying a
 * batch of synced offline changes (where retries can double-apply increments).
 * No-op when accountId is null.
 */
export async function recomputeBalance(tx, accountId) {
  if (!accountId) return;

  const account = await tx.account.findUnique({
    where: { id: accountId },
    select: { openingBalance: true },
  });
  if (!account) return;

  const [income, expense, transfersIn, transfersOut] = await Promise.all([
    tx.income.aggregate({
      _sum: { amount: true },
      where: { accountId, deletedAt: null },
    }),
    tx.expense.aggregate({
      _sum: { amount: true },
      where: { accountId, deletedAt: null },
    }),
    tx.transfer.aggregate({
      _sum: { amount: true },
      where: { toAccountId: accountId, deletedAt: null },
    }),
    tx.transfer.aggregate({
      _sum: { amount: true },
      where: { fromAccountId: accountId, deletedAt: null },
    }),
  ]);

  const num = (v) => parseFloat(v ?? 0);
  const balance =
    num(account.openingBalance) +
    num(income._sum.amount) -
    num(expense._sum.amount) +
    num(transfersIn._sum.amount) -
    num(transfersOut._sum.amount);

  await tx.account.update({ where: { id: accountId }, data: { balance } });
}

/**
 * Confirms an account exists and belongs to the user. Returns true/false.
 * Pass `tx` (or the base prisma client) as the first argument.
 */
export async function ownsAccount(tx, userId, accountId) {
  if (!accountId) return true;
  const account = await tx.account.findFirst({
    where: { id: accountId, userId, deletedAt: null },
    select: { id: true },
  });
  return account !== null;
}
