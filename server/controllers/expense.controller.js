import z from "zod";
import { Category, PaymentMethod } from "../src/generated/prisma/index.js";
import { prisma } from "../src/db.js";

const ExpenseSchema = z.object({
  amount: z.number().positive(),
  description: z.string().min(5).optional(),
  category: z.enum(Object.values(Category)).optional(),
  paymentMethod: z.enum(Object.values(PaymentMethod)).optional(),
});

const UpdateExpenseSchema = z
  .object({
    amount: z.number().positive().optional(),
    category: z.enum(Object.values(Category)).optional(),
    paymentMethod: z.enum(Object.values(PaymentMethod)).optional(),
    description: z.string().max(255).optional(),
  })
  .strict();

export const createExpense = async (req, res) => {
  const result = ExpenseSchema.safeParse(req.body);

  if (!result.success) {
    return res
      .status(400)
      .json({ message: "Invalid expense data", errors: result.error.errors });
  }

  const { amount, description, category, paymentMethod } = result.data;
  const userId = req.user.userId;

  const expense = await prisma.expense.create({
    data: {
      amount,
      description,
      category,
      paymentMethod,
      userId,
    },
  });

  return res
    .status(201)
    .json({ message: "Expense created successfully", expense });
};

export const getExpenses = async (req, res) => {
  const userId = req.user.userId;
  const { category, from, to } = req.query;

  const where = {
    userId,
    deletedAt: null,
  };

  if (category) where.category = category;

  if (from || to) {
    where.createdAt = {};
    if (from) where.createdAt.gte = new Date(from);
    if (to) where.createdAt.lte = new Date(to);
  }

  const expenses = await prisma.expense.findMany({
    where,
    orderBy: { createdAt: "desc" },
  });

  return res.status(200).json({ expenses });
};

/*

GET http://localhost:3000/expenses — all expenses
GET http://localhost:3000/expenses?category=food_and_drink — filtered
GET http://localhost:3000/expenses?from=2026-01-01&to=2026-12-31 — date range
*/

export const updateExpense = async (req, res) => {
  const { id } = req.params;
  const userId = req.user.userId;

  const result = UpdateExpenseSchema.safeParse(req.body);
  if (!result.success) {
    return res
      .status(400)
      .json({ message: "Invalid data", errors: result.error.errors });
  }

  const expense = await prisma.expense.findUnique({
    where: { id },
  });

  if (!expense || expense.deletedAt !== null) {
    return res.status(404).json({ message: "Expense not found" });
  }

  if (expense.userId !== userId) {
    return res.status(403).json({ message: "Forbidden" });
  }

  const updated = await prisma.expense.update({
    where: { id },
    data: result.data,
  });

  return res
    .status(200)
    .json({ message: "Expense updated successfully", expense: updated });
};

export const deleteExpense = async (req, res) => {
  const { id } = req.params;
  const userId = req.user.userId;

  const expense = await prisma.expense.findUnique({
    where: { id },
  });

  if (!expense || expense.deletedAt !== null) {
    return res.status(404).json({ message: "Expense not found" });
  }

  if (expense.userId !== userId) {
    return res.status(403).json({ message: "Forbidden" });
  }

  await prisma.expense.update({
    where: { id },
    data: {
      deletedAt: new Date(),
    },
  });

  return res.status(200).json({ message: "Expense deleted successfully" });
};

export const getExpenseSummary = async (req, res) => {
  const userId = req.user.userId;

  // 1. Total by category (all time)
  const byCategory = await prisma.expense.groupBy({
    by: ["category"],
    where: { userId, deletedAt: null },
    _sum: { amount: true },
  });

  // 4. All time total
  const allTime = await prisma.expense.aggregate({
    where: { userId, deletedAt: null },
    _sum: { amount: true },
  });

  // Fetch all expenses for JS-side grouping
  const expenses = await prisma.expense.findMany({
    where: { userId, deletedAt: null },
    select: { amount: true, createdAt: true, category: true },
  });

  // 2. Total by month
  const monthMap = {};
  // 3. Category breakdown per month
  const categoryByMonthMap = {};

  for (const expense of expenses) {
    const month = expense.createdAt.toISOString().slice(0, 7);
    const amount = parseFloat(expense.amount);

    // by month
    if (monthMap[month]) {
      monthMap[month] += amount;
    } else {
      monthMap[month] = amount;
    }

    // by category per month
    if (!categoryByMonthMap[month]) {
      categoryByMonthMap[month] = {};
    }
    if (categoryByMonthMap[month][expense.category]) {
      categoryByMonthMap[month][expense.category] += amount;
    } else {
      categoryByMonthMap[month][expense.category] = amount;
    }
  }

  const byMonth = Object.entries(monthMap).map(([month, total]) => ({
    month,
    total: total.toFixed(2),
  }));

  const byCategoryPerMonth = Object.entries(categoryByMonthMap).map(
    ([month, categories]) => ({
      month,
      categories: Object.entries(categories).map(([category, total]) => ({
        category,
        total: total.toFixed(2),
      })),
    }),
  );

  return res.status(200).json({
    allTimeTotal: parseFloat(allTime._sum.amount || 0).toFixed(2),
    byCategory,
    byMonth,
    byCategoryPerMonth,
  });
};
