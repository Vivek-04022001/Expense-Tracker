// src/validators/incomeValidator.js
import { z } from "zod";
import { IncomeType } from "../generated/prisma/index.js";

const incomeTypeValues = Object.values(IncomeType);

export const CreateIncomeSchema = z.object({
  amount: z
    .number({ required_error: "Amount is required" })
    .positive("Amount must be positive"),
  incomeType: z.enum(incomeTypeValues).default("other"),
  description: z.string().max(255).optional(),
});

export const UpdateIncomeSchema = CreateIncomeSchema.partial();

const dateRegex = /^\d{4}-\d{2}-\d{2}$/;

export const IncomeQuerySchema = z.object({
  from: z.string().regex(dateRegex, "Must be YYYY-MM-DD").optional(),
  to: z.string().regex(dateRegex, "Must be YYYY-MM-DD").optional(),
  incomeType: z.enum(incomeTypeValues).optional(),
});
