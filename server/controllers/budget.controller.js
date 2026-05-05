import { prisma } from "../src/db.js";

export const upsertBudget = async (req, res) => {
  const userId = req.user.userId;
  const { category, limitAmount, month, year } = req.body;
  const budget = await prisma.budget.upsert({
    where: {
      userId_category_month_year: { userId, category, month, year },
    },
    update: { limitAmount },
    create: { userId, category, limitAmount, month, year },
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
  try {
    const userId = req.user.userId;
    const { id } = req.params;

    const budget = await prisma.budget.findFirst({
      where: { id, userId },
    });

    if (!budget) return res.status(404).json({ message: "Budget not found" });

    await prisma.budget.delete({ where: { id } });

    return res.status(200).json({ message: "Budget deleted successfully" });
  } catch (err) {
    console.error("deleteBudget error:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
};

export const getBudgetStatus = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { id } = req.params;

    // Ownership check — ensure this budget belongs to the user
    const budget = await prisma.budget.findFirst({
      where: { id, userId },
    });

    if (!budget) return res.status(404).json({ error: "Budget not found" });

    // Build date range for the budget's month + year
    const startDate = new Date(budget.year, budget.month - 1, 1);
    const endDate = new Date(budget.year, budget.month, 1);

    // Sum all non-deleted expenses matching category + date window
    const result = await prisma.expense.aggregate({
      _sum: { amount: true },
      where: {
        userId,
        category: budget.category,
        deletedAt: null,
        createdAt: {
          gte: startDate,
          lt: endDate,
        },
      },
    });

    // Prisma returns Decimal objects — convert to plain numbers
    const spent = parseFloat(result._sum.amount ?? 0);
    const limit = parseFloat(budget.limitAmount);
    const remaining = limit - spent;
    const percentUsed = parseFloat(((spent / limit) * 100).toFixed(1));

    return res.status(200).json({
      budget: {
        id: budget.id,
        category: budget.category,
        month: budget.month,
        year: budget.year,
        limitAmount: limit,
      },
      status: {
        spent,
        remaining,
        percentUsed,
        isOverBudget: spent > limit,
      },
    });
  } catch (err) {
    console.error("getBudgetStatus error:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
};
