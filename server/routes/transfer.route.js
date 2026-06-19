import { Router } from "express";
import { authenticateToken } from "../middleware/auth.middleware.js";
import {
  createTransfer,
  getTransfers,
  deleteTransfer,
} from "../controllers/transfer.controller.js";
import { CreateTransferSchema } from "../src/validators/transferValidator.js";
import { validate } from "../middleware/validate.js";

const router = Router();
router.use(authenticateToken);

router.get("/", getTransfers);
router.post("/", validate(CreateTransferSchema), createTransfer);
router.delete("/:id", deleteTransfer);

export default router;
