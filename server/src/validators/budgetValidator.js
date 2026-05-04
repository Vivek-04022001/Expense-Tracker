import { z } from "zod";
import { Category } from "../generated/prisma/index.js";

export const BudgetSchema = z.object({
  category: z.nativeEnum(Category),
  limitAmount: z.number().positive(),
  month: z.number().int().min(1).max(12),
  year: z.number().int().min(2024).max(2100),
});
