import express from "express";
import cors from "cors";
import healthRoute from "./routes/health.route.js";
import authRoute from "./routes/auth.route.js";
import expenseRouter from "./routes/expense.route.js";
import budgetRouter from "./routes/budget.route.js";
import savingsRouter from "./routes/savings.route.js";
import incomeRouter from "./routes/income.route.js";
import accountRouter from "./routes/account.route.js";
import transferRouter from "./routes/transfer.route.js";
import categoryRouter from "./routes/category.route.js";
import syncRouter from "./routes/sync.routes.js";

const app = express();
app.use(cors());
app.use(express.json());

app.use("/", healthRoute);
app.use("/auth", authRoute);
app.use("/expenses", expenseRouter);
app.use("/budgets", budgetRouter);
app.use("/savings", savingsRouter);
app.use("/income", incomeRouter);
app.use("/accounts", accountRouter);
app.use("/transfers", transferRouter);
app.use("/categories", categoryRouter);
app.use("/sync", syncRouter);

export default app;
