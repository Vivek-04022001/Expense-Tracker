import { Router } from "express";
import { authenticateToken } from "../middleware/auth.middleware.js";
import {
  upsertBudget,
  getBudgets,
  deleteBudget,
} from "../controllers/budget.controller.js";
import { BudgetSchema } from "../src/validators/budgetValidator.js";
import { validate } from "../middleware/validate.js";

const router = Router();
router.use(authenticateToken);

router.get("/", getBudgets);
router.put("/", validate(BudgetSchema), upsertBudget);
router.delete("/:id", deleteBudget);

export default router;
