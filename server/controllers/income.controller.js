import { prisma } from "../src/db.js";
import {
  CreateIncomeSchema,
  UpdateIncomeSchema,
  IncomeQuerySchema,
} from "../src/validators/incomeValidator.js";
import { applyDelta, ownsAccount } from "../services/balance.service.js";

export const createIncome = async (req, res) => {
  const result = CreateIncomeSchema.safeParse(req.body);

  if (!result.success) {
    return res
      .status(400)
      .json({ message: "Invalid income data", errors: result.error.errors });
  }

  const { amount, incomeType, description, accountId } = result.data;
  const userId = req.user.userId;

  if (!(await ownsAccount(prisma, userId, accountId))) {
    return res.status(400).json({ message: "Invalid account" });
  }

  const income = await prisma.$transaction(async (tx) => {
    const created = await tx.income.create({
      data: { amount, incomeType, description, accountId, userId },
    });
    // Income increases the account balance.
    await applyDelta(tx, accountId, amount);
    return created;
  });

  return res
    .status(201)
    .json({ message: "Income created successfully", income });
};

export const getIncomes = async (req, res) => {
  const result = IncomeQuerySchema.safeParse(req.query);
  if (!result.success) {
    return res.status(400).json({ error: result.error.flatten().fieldErrors });
  }

  const { from, to, incomeType } = result.data;
  const userId = req.user.userId;

  const where = { userId };

  if (incomeType) where.incomeType = incomeType;

  if (from || to) {
    where.createdAt = {};
    if (from) where.createdAt.gte = new Date(from);
    if (to) where.createdAt.lte = new Date(to);
  }

  const incomes = await prisma.income.findMany({
    where,
    orderBy: { createdAt: "desc" },
  });

  return res.status(200).json(incomes);
};

export const updateIncome = async (req, res) => {
  const result = UpdateIncomeSchema.safeParse(req.body);

  if (!result.success) {
    return res
      .status(400)
      .json({ message: "Invalid income data", errors: result.error.errors });
  }

  const { id } = req.params;
  const userId = req.user.userId;

  const income = await prisma.income.findFirst({
    where: { id, userId },
  });

  if (!income) return res.status(404).json({ message: "Income not found" });

  const data = result.data;
  const newAccountId = "accountId" in data ? data.accountId : income.accountId;

  if (
    "accountId" in data &&
    data.accountId &&
    !(await ownsAccount(prisma, userId, data.accountId))
  ) {
    return res.status(400).json({ message: "Invalid account" });
  }

  const oldAmount = parseFloat(income.amount);
  const newAmount = data.amount ?? oldAmount;

  const updated = await prisma.$transaction(async (tx) => {
    const result = await tx.income.update({ where: { id }, data });
    // Reverse old effect, apply new (income increases balance).
    await applyDelta(tx, income.accountId, -oldAmount);
    await applyDelta(tx, newAccountId, newAmount);
    return result;
  });

  return res
    .status(200)
    .json({ message: "Income updated successfully", income: updated });
};

export const deleteIncome = async (req, res) => {
  const { id } = req.params;
  const userId = req.user.userId;

  const income = await prisma.income.findFirst({
    where: { id, userId },
  });

  if (!income) return res.status(404).json({ message: "Income not found" });

  await prisma.$transaction(async (tx) => {
    await tx.income.delete({ where: { id } });
    // Reverse the income: remove the amount from the account.
    await applyDelta(tx, income.accountId, -parseFloat(income.amount));
  });

  return res.status(204).send();
};
