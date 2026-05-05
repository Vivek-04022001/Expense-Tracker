import { prisma } from "../src/db.js";
import {
  CreateIncomeSchema,
  UpdateIncomeSchema,
  IncomeQuerySchema,
} from "../src/validators/incomeValidator.js";

export const createIncome = async (req, res) => {
  const result = CreateIncomeSchema.safeParse(req.body);

  if (!result.success) {
    return res
      .status(400)
      .json({ message: "Invalid income data", errors: result.error.errors });
  }

  const { amount, incomeType, description } = result.data;
  const userId = req.user.userId;

  const income = await prisma.income.create({
    data: {
      amount,
      incomeType,
      description,
      userId,
    },
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

  const updated = await prisma.income.update({
    where: { id },
    data: result.data,
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

  await prisma.income.delete({
    where: { id },
  });

  return res.status(204).send();
};
