import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../models/savings_model.dart';

/// Offline-first savings summary, computed locally from Drift: total income vs
/// total expenses (non-deleted) in the given window, plus the savings rate.
class SavingsRepository {
  SavingsRepository(this._db);

  final AppDatabase _db;

  Future<SavingsModel> getSummary({DateTime? from, DateTime? to}) async {
    final incomeQuery = _db.select(_db.incomes)
      ..where((t) => t.deletedAt.isNull());
    final expenseQuery = _db.select(_db.expenses)
      ..where((t) => t.deletedAt.isNull());
    if (from != null) {
      incomeQuery.where((t) => t.createdAt.isBiggerOrEqualValue(from));
      expenseQuery.where((t) => t.createdAt.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      incomeQuery.where((t) => t.createdAt.isSmallerOrEqualValue(to));
      expenseQuery.where((t) => t.createdAt.isSmallerOrEqualValue(to));
    }

    final incomes = await incomeQuery.get();
    final expenses = await expenseQuery.get();

    final totalIncome = incomes.fold<double>(0, (s, r) => s + r.amount);
    final totalExpenses = expenses.fold<double>(0, (s, r) => s + r.amount);
    final netSavings = totalIncome - totalExpenses;
    final savingsRate =
        totalIncome == 0 ? 0.0 : (netSavings / totalIncome) * 100;

    return SavingsModel(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netSavings: netSavings,
      savingsRate: double.parse(savingsRate.toStringAsFixed(2)),
    );
  }
}
