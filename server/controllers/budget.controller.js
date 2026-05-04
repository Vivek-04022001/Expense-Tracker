import { prisma } from "../src/db.js";

export const upsertBudget = async (req, res) => {
  const userId = req.user.userId;
  const { category, limitAmount, month, year } = req.body;
  const budget = await prisma.budget.upsert({
    where: {
      userId_category_month_year: {
        userId,
        category,
        month,
        year,
      },
      update: { limitAmount },
      create: {
        userId,
        category,
        limitAmount,
        month,
        year,
      },
    },
  });

  return res
    .status(200)
    .json({ message: "Budget upserted successfully", budget });
};

export const getBudgets = async (req, res) => {
  const userId = req.user.userId;
  const { month, year } = req.query;

  const budgets = await prisma.budget.findMany({
    where: {
      userId,
      ...(month && { month: parseInt(month) }),
      ...(year && { year: parseInt(year) }),
    },
    orderBy: { category: "asc" },
  });
  return res
    .status(200)
    .json({ message: "Budgets retrieved successfully", budgets });
};

export const deleteBudget = async (req, res) => {
  const userId = req.user.userId;
  const { id } = req.params;

  const budget = await prisma.budget.findFirst({
    where: { id, userId },
  });

  if (!budget) return res.status(404).json({ message: "Budget not found" });

  await prisma.budget.delete({
    where: { id },
  });

  return res.status(200).json({ message: "Budget deleted successfully" });
};
