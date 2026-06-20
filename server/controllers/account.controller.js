import { prisma } from "../src/db.js";
import { recomputeBalance } from "../services/balance.service.js";

const serialize = (account) => ({
  id: account.id,
  name: account.name,
  type: account.type,
  balance: parseFloat(account.balance),
  color: account.color,
  createdAt: account.createdAt,
  updatedAt: account.updatedAt,
});

export const createAccount = async (req, res) => {
  const userId = req.user.userId;
  const { name, type, balance, color } = req.body;

  // The entered amount is the account's starting point. `balance` is derived
  // from openingBalance + activity, so a brand-new account's balance equals it.
  const opening = balance ?? 0;
  const account = await prisma.account.create({
    data: {
      name,
      type,
      openingBalance: opening,
      balance: opening,
      color,
      userId,
    },
  });

  return res
    .status(201)
    .json({ message: "Account created successfully", account: serialize(account) });
};

export const getAccounts = async (req, res) => {
  const userId = req.user.userId;

  const accounts = await prisma.account.findMany({
    where: { userId, deletedAt: null },
    orderBy: { createdAt: "asc" },
  });

  const serialized = accounts.map(serialize);
  const totalBalance = serialized.reduce((sum, a) => sum + a.balance, 0);

  return res.status(200).json({ accounts: serialized, totalBalance });
};

export const updateAccount = async (req, res) => {
  const userId = req.user.userId;
  const { id } = req.params;

  const account = await prisma.account.findFirst({
    where: { id, userId, deletedAt: null },
  });

  if (!account) return res.status(404).json({ message: "Account not found" });

  const { name, type, color, balance } = req.body;
  const data = {};
  if (name !== undefined) data.name = name;
  if (type !== undefined) data.type = type;
  if (color !== undefined) data.color = color;

  // Editing the displayed balance shifts openingBalance so the recomputed
  // balance lands on the entered value while preserving existing activity.
  let recompute = false;
  if (balance !== undefined) {
    const activity = parseFloat(account.balance) - parseFloat(account.openingBalance);
    data.openingBalance = parseFloat(balance) - activity;
    recompute = true;
  }

  const updated = await prisma.$transaction(async (tx) => {
    const row = await tx.account.update({ where: { id }, data });
    if (recompute) await recomputeBalance(tx, id);
    return tx.account.findUnique({ where: { id } });
  });

  return res
    .status(200)
    .json({ message: "Account updated successfully", account: serialize(updated) });
};

export const deleteAccount = async (req, res) => {
  const userId = req.user.userId;
  const { id } = req.params;

  const account = await prisma.account.findFirst({
    where: { id, userId, deletedAt: null },
  });

  if (!account) return res.status(404).json({ message: "Account not found" });

  await prisma.account.update({
    where: { id },
    data: { deletedAt: new Date() },
  });

  return res.status(200).json({ message: "Account deleted successfully" });
};
