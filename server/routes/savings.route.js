import { Router } from "express";
import { authenticateToken } from "../middleware/auth.middleware.js";
import { getSavingsSummary } from "../controllers/savings.controller.js";

const router = Router();

router.get("/summary", authenticateToken, getSavingsSummary);

export default router;
