import { prisma } from "../src/db.js";
import { applyDelta, ownsAccount } from "../services/balance.service.js";

const serialize = (t) => ({
  id: t.id,
  amount: parseFloat(t.amount),
  description: t.description,
  fromAccountId: t.fromAccountId,
  toAccountId: t.toAccountId,
  createdAt: t.createdAt,
});

export const createTransfer = async (req, res) => {
  const userId = req.user.userId;
  const { amount, fromAccountId, toAccountId, description } = req.body;

  const ownsBoth =
    (await ownsAccount(prisma, userId, fromAccountId)) &&
    (await ownsAccount(prisma, userId, toAccountId));
  if (!ownsBoth) {
    return res.status(400).json({ message: "Invalid account" });
  }

  const transfer = await prisma.$transaction(async (tx) => {
    const created = await tx.transfer.create({
      data: { amount, fromAccountId, toAccountId, description, userId },
    });
    await applyDelta(tx, fromAccountId, -amount);
    await applyDelta(tx, toAccountId, amount);
    return created;
  });

  return res.status(201).json({
    message: "Transfer created successfully",
    transfer: serialize(transfer),
  });
};

export const getTransfers = async (req, res) => {
  const userId = req.user.userId;
  const { from, to } = req.query;

  const where = { userId, deletedAt: null };
  if (from || to) {
    where.createdAt = {};
    if (from) where.createdAt.gte = new Date(from);
    if (to) where.createdAt.lte = new Date(to);
  }

  const transfers = await prisma.transfer.findMany({
    where,
    orderBy: { createdAt: "desc" },
  });

  return res.status(200).json({ transfers: transfers.map(serialize) });
};

export const deleteTransfer = async (req, res) => {
  const userId = req.user.userId;
  const { id } = req.params;

  const transfer = await prisma.transfer.findFirst({
    where: { id, userId, deletedAt: null },
  });

  if (!transfer) {
    return res.status(404).json({ message: "Transfer not found" });
  }

  await prisma.$transaction(async (tx) => {
    await tx.transfer.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
    // Reverse the movement.
    const amount = parseFloat(transfer.amount);
    await applyDelta(tx, transfer.fromAccountId, amount);
    await applyDelta(tx, transfer.toAccountId, -amount);
  });

  return res.status(200).json({ message: "Transfer deleted successfully" });
};
