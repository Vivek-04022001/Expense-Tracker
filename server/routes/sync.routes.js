import { Router } from "express";
import { pull, push } from "../controllers/sync.controller.js";
import { authenticateToken } from "../middleware/auth.middleware.js";

const router = Router();

router.get("/pull", authenticateToken, pull);
router.post("/push", authenticateToken, push);

export default router;
