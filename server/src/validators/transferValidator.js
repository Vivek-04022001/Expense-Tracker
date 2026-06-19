import z from "zod";

export const CreateTransferSchema = z
  .object({
    amount: z.number().positive(),
    fromAccountId: z.string().uuid(),
    toAccountId: z.string().uuid(),
    description: z.string().max(255).optional(),
  })
  .refine((data) => data.fromAccountId !== data.toAccountId, {
    message: "From and To accounts must be different",
    path: ["toAccountId"],
  });
