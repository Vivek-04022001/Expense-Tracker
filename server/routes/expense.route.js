import { Router } from "express";
import {
  createExpense,
  getExpenses,
} from "../controllers/expense.controller.js";
import { authenticateToken } from "../middleware/auth.middleware.js";

const router = Router();

router.post("/", authenticateToken, createExpense);
router.get("/", authenticateToken, getExpenses);

export default router;
