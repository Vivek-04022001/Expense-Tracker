import { Router } from "express";
import { authenticateToken } from "../middleware/auth.middleware.js";
import {
  getCategories,
  createCategory,
  updateCategory,
  deleteCategory,
} from "../controllers/category.controller.js";
import {
  CreateCategorySchema,
  UpdateCategorySchema,
} from "../src/validators/categoryValidator.js";
import { validate } from "../middleware/validate.js";

const router = Router();
router.use(authenticateToken);

router.get("/", getCategories);
router.post("/", validate(CreateCategorySchema), createCategory);
router.patch("/:id", validate(UpdateCategorySchema), updateCategory);
router.delete("/:id", deleteCategory);

export default router;
