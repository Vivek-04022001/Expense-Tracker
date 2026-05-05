import { Router } from "express";
import { authenticateToken } from "../middleware/auth.middleware.js";
import {
  createIncome,
  getIncomes,
  updateIncome,
  deleteIncome,
} from "../controllers/income.controller.js";

const router = Router();

router.post("/", authenticateToken, createIncome);
router.get("/", authenticateToken, getIncomes);
router.patch("/:id", authenticateToken, updateIncome);
router.delete("/:id", authenticateToken, deleteIncome);

export default router;
