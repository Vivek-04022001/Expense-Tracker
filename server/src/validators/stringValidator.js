import { z } from "zod";

const dateRegex = /^\d{4}-\d{2}-\d{2}$/;

export const SummaryQuerySchema = z.object({
  from: z.string().regex(dateRegex, "Must be YYYY-MM-DD").optional(),
  to: z.string().regex(dateRegex, "Must be YYYY-MM-DD").optional(),
});
