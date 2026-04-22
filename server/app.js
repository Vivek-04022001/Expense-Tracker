import express from "express";
import healthRoute from "./routes/health.route.js";
import authRoute from "./routes/auth.route.js";

const app = express();

app.use(express.json());

app.use("/", healthRoute);
app.use("/auth", authRoute);

export default app;
