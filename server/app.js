import express from "express";
import healthRoute from "./routes/health.route.js";
import authRoute from "./routes/auth.route.js";
import expenseRouter from "./routes/expense.route.js";
import budgetRouter from "./routes/budget.route.js";
import savingsRouter from "./routes/savings.route.js";
import incomeRouter from "./routes/income.route.js";

const app = express();

app.use(express.json());

app.use("/", healthRoute);
app.use("/auth", authRoute);
app.use("/expenses", expenseRouter);
app.use("/budgets", budgetRouter);
app.use("/savings", savingsRouter);
app.use("/income", incomeRouter);

export default app;
