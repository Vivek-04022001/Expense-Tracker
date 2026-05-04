import z from "zod";
import { Category, PaymentMethod } from "@prisma/client";
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
