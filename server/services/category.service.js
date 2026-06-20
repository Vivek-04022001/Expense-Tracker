/**
 * Confirms a category exists, belongs to the user, and matches the expected
 * kind ("expense" | "income"). Returns true when categoryId is null/undefined
 * so the link stays optional. Pass `tx` (or the base prisma client) first.
 */
export async function ownsCategory(tx, userId, categoryId, kind) {
  if (!categoryId) return true;
  const category = await tx.transactionCategory.findFirst({
    where: { id: categoryId, userId, kind, deletedAt: null },
    select: { id: true },
  });
  return category !== null;
}
