import { Router } from "express";
import { authenticateToken } from "../middleware/auth.middleware.js";
import {
  createAccount,
  getAccounts,
  updateAccount,
  deleteAccount,
} from "../controllers/account.controller.js";
import {
  CreateAccountSchema,
  UpdateAccountSchema,
} from "../src/validators/accountValidator.js";
import { validate } from "../middleware/validate.js";

const router = Router();
router.use(authenticateToken);

router.get("/", getAccounts);
router.post("/", validate(CreateAccountSchema), createAccount);
router.put("/:id", validate(UpdateAccountSchema), updateAccount);
router.delete("/:id", deleteAccount);

export default router;
