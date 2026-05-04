import { Router } from "express";
import {
  createExpense,
  getExpenses,
  updateExpense,
  deleteExpense,
  getExpenseSummary,
} from "../controllers/expense.controller.js";
import { authenticateToken } from "../middleware/auth.middleware.js";

const router = Router();

router.post("/", authenticateToken, createExpense);
router.get("/", authenticateToken, getExpenses);
router.put("/:id", authenticateToken, updateExpense);
router.delete("/:id", authenticateToken, deleteExpense);
router.get("/summary", authenticateToken, getExpenseSummary);

export default router;
