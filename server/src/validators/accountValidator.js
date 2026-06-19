import z from "zod";
import { AccountType } from "../generated/prisma/index.js";

const hexColor = z
  .string()
  .regex(/^#?[0-9a-fA-F]{6}$/, "color must be a 6-digit hex value")
  .optional();

export const CreateAccountSchema = z.object({
  name: z.string().min(1).max(60),
  type: z.nativeEnum(AccountType).optional(),
  balance: z.number().optional(),
  color: hexColor,
});

export const UpdateAccountSchema = z
  .object({
    name: z.string().min(1).max(60).optional(),
    type: z.nativeEnum(AccountType).optional(),
    balance: z.number().optional(),
    color: hexColor,
  })
  .strict();
