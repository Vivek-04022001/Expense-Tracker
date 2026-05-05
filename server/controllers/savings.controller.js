import { prisma } from "../src/db.js";
import { SummaryQuerySchema } from "../src/validators/stringValidator.js";

export const getSavingsSummary = async (req, res) => {
  const result = SummaryQuerySchema.safeParse(req.query);
  if (!result.success) {
    return res.status(400).json({ error: result.error.flatten().fieldErrors });
  }

  const { from, to } = result.data;
  const userId = req.user.userId;

  const dateFilter = {};
  if (from) dateFilter.gte = new Date(from);
  if (to) dateFilter.lte = new Date(to);

  const hasDateFilter = Object.keys(dateFilter).length > 0;

  const [incomeResult, expenseResult] = await Promise.all([
    prisma.income.aggregate({
      where: {
        userId,
        ...(hasDateFilter && { createdAt: dateFilter }),
      },
      _sum: { amount: true },
    }),

    prisma.expense.aggregate({
      where: {
        userId,
        deletedAt: null,
        ...(hasDateFilter && { createdAt: dateFilter }),
      },
      _sum: { amount: true },
    }),
  ]);

  const totalIncome = Number(incomeResult._sum.amount ?? 0);
  const totalExpenses = Number(expenseResult._sum.amount ?? 0);
  const netSavings = totalIncome - totalExpenses;
  const savingsRate =
    totalIncome > 0
      ? parseFloat(((netSavings / totalIncome) * 100).toFixed(2))
      : 0;

  return res.status(200).json({
    totalIncome,
    totalExpenses,
    netSavings,
    savingsRate,
  });
};
