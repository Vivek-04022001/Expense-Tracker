import { prisma } from "../src/db.js";
import { recomputeBalance } from "../services/balance.service.js";

/**
 * Sync controller — the contract between the offline-first mobile client and
 * the server. Two endpoints:
 *
 *   GET  /sync/pull?since=<ISO>  → every row changed after `since` (delta pull)
 *   POST /sync/push             → a batch of client mutations (upsert/delete)
 *
 * Design notes:
 * - IDs are client-generated UUIDs, so upserts work without an ID-remapping step.
 * - Conflicts resolve Last-Write-Wins: an incoming change is skipped when the
 *   stored row's `updatedAt` is newer than the change's `updatedAt`.
 * - Deletes are soft (set `deletedAt`) so they propagate through the delta pull.
 * - Account balances are derived (recomputeBalance) after a push rather than
 *   incrementally adjusted, which keeps replays idempotent.
 */

// Per-entity config: which fields the client may write, and which of those
// fields point at an account whose balance must be recomputed after a change.
const ENTITIES = {
  account: {
    model: "account",
    fields: ["name", "type", "openingBalance", "color"],
    // The account row is itself the account to recompute (by its own id).
    selfAccount: true,
    accountFields: [],
  },
  category: {
    model: "transactionCategory",
    fields: ["name", "kind", "icon", "color", "key", "isSystem", "sortOrder"],
    accountFields: [],
  },
  expense: {
    model: "expense",
    fields: ["amount", "category", "paymentMethod", "description", "accountId", "categoryId"],
    accountFields: ["accountId"],
  },
  income: {
    model: "income",
    fields: ["amount", "incomeType", "description", "accountId", "categoryId"],
    accountFields: ["accountId"],
  },
  transfer: {
    model: "transfer",
    fields: ["amount", "description", "fromAccountId", "toAccountId"],
    accountFields: ["fromAccountId", "toAccountId"],
  },
  budget: {
    model: "budget",
    fields: ["limitAmount", "category", "categoryId", "month", "year"],
    accountFields: [],
  },
};

// Map a sync entity key → the `changes` key used in the pull response.
const PULL_KEYS = {
  account: "accounts",
  category: "categories",
  expense: "expenses",
  income: "income",
  transfer: "transfers",
  budget: "budgets",
};

/** Pick only the allowed, defined fields from an incoming op payload. */
function pickFields(data, fields) {
  const out = {};
  for (const f of fields) {
    if (data[f] !== undefined) out[f] = data[f];
  }
  return out;
}

export const pull = async (req, res) => {
  const userId = req.user.userId;
  const sinceRaw = req.query.since;

  // Default to the epoch for a first-run full pull.
  let since = new Date(0);
  if (sinceRaw) {
    const parsed = new Date(sinceRaw);
    if (!isNaN(parsed.getTime())) since = parsed;
  }

  const serverTime = new Date();
  const where = { userId, updatedAt: { gt: since } };
  const orderBy = { updatedAt: "asc" };

  // Include soft-deleted rows so deletes propagate to the client.
  const [accounts, categories, expenses, income, transfers, budgets] =
    await Promise.all([
      prisma.account.findMany({ where, orderBy }),
      prisma.transactionCategory.findMany({ where, orderBy }),
      prisma.expense.findMany({ where, orderBy }),
      prisma.income.findMany({ where, orderBy }),
      prisma.transfer.findMany({ where, orderBy }),
      prisma.budget.findMany({ where, orderBy }),
    ]);

  return res.status(200).json({
    serverTime: serverTime.toISOString(),
    changes: { accounts, categories, expenses, income, transfers, budgets },
  });
};

export const push = async (req, res) => {
  const userId = req.user.userId;
  const operations = req.body?.operations;

  if (!Array.isArray(operations)) {
    return res.status(400).json({ message: "operations must be an array" });
  }

  const results = [];
  const accountsToRecompute = new Set();

  try {
    await prisma.$transaction(async (tx) => {
      for (let i = 0; i < operations.length; i++) {
        const operation = operations[i];
        const { entity, op, id, data = {}, updatedAt } = operation || {};
        const config = ENTITIES[entity];

        // Validate the operation envelope.
        if (!config || !id || (op !== "upsert" && op !== "delete")) {
          results.push({ index: i, id, status: "error", reason: "invalid-operation" });
          continue;
        }

        const model = tx[config.model];
        const incomingUpdatedAt = updatedAt ? new Date(updatedAt) : new Date();

        const existing = await model.findUnique({ where: { id } });

        // Ownership: never trust a client-supplied userId.
        if (existing && existing.userId !== userId) {
          results.push({ index: i, id, status: "error", reason: "forbidden" });
          continue;
        }

        // Last-Write-Wins: skip changes the server has already superseded.
        if (existing && existing.updatedAt > incomingUpdatedAt) {
          results.push({ index: i, id, status: "skipped-stale" });
          continue;
        }

        // Track every account touched (old + new links) for balance recompute.
        const trackAccounts = (row) => {
          if (!row) return;
          if (config.selfAccount && row.id) accountsToRecompute.add(row.id);
          for (const f of config.accountFields) {
            if (row[f]) accountsToRecompute.add(row[f]);
          }
        };
        trackAccounts(existing);
        trackAccounts(data);
        if (config.selfAccount) accountsToRecompute.add(id);

        if (op === "delete") {
          if (existing && !existing.deletedAt) {
            await model.update({ where: { id }, data: { deletedAt: new Date() } });
          }
          results.push({ index: i, id, status: "applied" });
          continue;
        }

        // upsert
        const fields = pickFields(data, config.fields);
        if (existing) {
          await model.update({ where: { id }, data: { ...fields, deletedAt: null } });
        } else {
          await model.create({ data: { ...fields, id, userId } });
        }
        results.push({ index: i, id, status: "applied" });
      }

      // Recompute derived balances once per affected account, inside the txn.
      for (const accountId of accountsToRecompute) {
        await recomputeBalance(tx, accountId);
      }
    });
  } catch (err) {
    console.error("sync push error:", err);
    return res.status(500).json({ message: "Sync push failed" });
  }

  return res.status(200).json({ results });
};

// Re-exported for clarity; PULL_KEYS documents the response shape consumers map.
export { PULL_KEYS };
