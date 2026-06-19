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
