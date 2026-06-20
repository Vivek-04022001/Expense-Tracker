import { z } from "zod";

const hexColor = z
  .string()
  .regex(/^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/, "Must be a hex color like #FF6B4A");

export const CreateCategorySchema = z.object({
  name: z.string().trim().min(1, "Name is required").max(40),
  kind: z.enum(["expense", "income"]),
  icon: z.string().trim().min(1).max(40),
  color: hexColor,
});

// Custom categories only: name/icon/color editable. `kind` and `key` are immutable.
export const UpdateCategorySchema = z
  .object({
    name: z.string().trim().min(1).max(40).optional(),
    icon: z.string().trim().min(1).max(40).optional(),
    color: hexColor.optional(),
    sortOrder: z.number().int().optional(),
  })
  .strict()
  .refine((d) => Object.keys(d).length > 0, { message: "Nothing to update" });

export const CategoryQuerySchema = z.object({
  kind: z.enum(["expense", "income"]).optional(),
});
