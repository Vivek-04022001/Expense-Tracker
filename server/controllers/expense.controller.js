import z from "zod";
import { Category, PaymentMethod } from "../src/generated/prisma/index.js";
import { prisma } from "../src/db.js";

const ExpenseSchema = z.object({
  amount: z.number().positive(),
  description: z.string().min(5).optional(),
  category: z.enum(Object.values(Category)).optional(),
  paymentMethod: z.enum(Object.values(PaymentMethod)).optional(),
});

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
