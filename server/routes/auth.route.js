import { Router } from "express";
import {
  registerUser,
  loginUser,
  refreshToken,
  logoutUser,
  updateProfile,
} from "../controllers/auth.controller.js";
import { authenticateToken } from "../middleware/auth.middleware.js";

const router = Router();

router.post("/register", registerUser);

router.post("/login", loginUser);

router.post("/refresh-token", refreshToken);

router.post("/logout", logoutUser);

router.patch("/me", authenticateToken, updateProfile);

export default router;
