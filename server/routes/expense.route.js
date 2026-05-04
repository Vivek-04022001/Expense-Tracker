import { Router } from "express";
import { createExpense } from "../controllers/expense.controller.js";
import { authenticateToken } from "../middleware/auth.middleware.js";

const router = Router();

router.post("/", authenticateToken, createExpense);

export default router;
