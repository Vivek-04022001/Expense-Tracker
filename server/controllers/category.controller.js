import { prisma } from "../src/db.js";
import { seedBuiltinCategories } from "../src/constants/categorySeed.js";

const serialize = (c) => ({
  id: c.id,
  name: c.name,
  kind: c.kind,
  icon: c.icon,
  color: c.color,
  key: c.key,
  isSystem: c.isSystem,
  sortOrder: c.sortOrder,
  createdAt: c.createdAt,
});

export const getCategories = async (req, res) => {
  const userId = req.user.userId;
  const { kind } = req.query;

  // Lazily seed built-ins for users created before the categories migration
  // (or whose seeding was skipped). Idempotent.
  await seedBuiltinCategories(prisma, userId);

  const where = { userId, deletedAt: null };
  if (kind) where.kind = kind;

  const categories = await prisma.transactionCategory.findMany({
    where,
    orderBy: [{ kind: "asc" }, { sortOrder: "asc" }, { createdAt: "asc" }],
  });

  return res.status(200).json({ categories: categories.map(serialize) });
};

export const createCategory = async (req, res) => {
  const userId = req.user.userId;
  const { name, kind, icon, color } = req.body;

  // Place new custom categories after existing ones of the same kind.
  const last = await prisma.transactionCategory.findFirst({
    where: { userId, kind, deletedAt: null },
    orderBy: { sortOrder: "desc" },
    select: { sortOrder: true },
  });

  const category = await prisma.transactionCategory.create({
    data: {
      userId,
      name,
      kind,
      icon,
      color,
      key: null,
      isSystem: false,
      sortOrder: (last?.sortOrder ?? -1) + 1,
    },
  });

  return res
    .status(201)
    .json({ message: "Category created successfully", category: serialize(category) });
};

export const updateCategory = async (req, res) => {
  const userId = req.user.userId;
  const { id } = req.params;

  const category = await prisma.transactionCategory.findFirst({
    where: { id, userId, deletedAt: null },
  });
  if (!category) {
    return res.status(404).json({ message: "Category not found" });
  }

  // Display attributes (name/icon/color/sortOrder) are editable for both custom
  // and system categories. `kind` and `key` stay immutable so charts and budget
  // aggregation keep resolving built-ins.
  const updated = await prisma.transactionCategory.update({
    where: { id },
    data: req.body,
  });

  return res
    .status(200)
    .json({ message: "Category updated successfully", category: serialize(updated) });
};

export const deleteCategory = async (req, res) => {
  const userId = req.user.userId;
  const { id } = req.params;

  const category = await prisma.transactionCategory.findFirst({
    where: { id, userId, deletedAt: null },
  });
  if (!category) {
    return res.status(404).json({ message: "Category not found" });
  }

  // System (built-in) categories cannot be deleted — they back the legacy enum
  // keys used by reporting. Users can edit them instead.
  if (category.isSystem) {
    return res
      .status(400)
      .json({ message: "Built-in categories cannot be deleted" });
  }

  await prisma.transactionCategory.update({
    where: { id },
    data: { deletedAt: new Date() },
  });

  return res.status(200).json({ message: "Category deleted successfully" });
};
