import { prisma } from "../src/db.js";

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

  const account = await prisma.account.create({
    data: {
      name,
      type,
      balance: balance ?? 0,
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

  const updated = await prisma.account.update({
    where: { id },
    data: req.body,
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
