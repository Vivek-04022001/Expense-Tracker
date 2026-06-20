import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/accounts/presentation/providers/account_provider.dart';
import '../../features/budgets/presentation/providers/budget_provider.dart';
import '../../features/categories/presentation/providers/category_provider.dart';
import '../../features/expenses/presentation/providers/expense_provider.dart';
import '../../features/income/presentation/providers/income_provider.dart';
import '../../features/savings/presentation/providers/savings_provider.dart';
import '../../features/transfers/presentation/providers/transfer_provider.dart';

/// Invalidates every read provider that sources from the local database, forcing
/// a re-read after a sync has changed Drift's contents. Called after a bootstrap
/// or background pull so the UI reflects freshly downloaded data. Accepts either
/// a [Ref] or a [WidgetRef] (both expose `invalidate`).
void refreshAllData(Ref ref) {
  // Expenses
  ref.invalidate(expenseListNotifierProvider);
  ref.invalidate(expenseSummaryProvider);
  ref.invalidate(currentMonthExpensesProvider);
  ref.invalidate(expensesForMonthProvider);
  // Income
  ref.invalidate(incomeListNotifierProvider);
  ref.invalidate(currentMonthIncomesProvider);
  ref.invalidate(incomesForMonthProvider);
  // Accounts
  ref.invalidate(accountListNotifierProvider);
  // Budgets
  ref.invalidate(budgetListNotifierProvider);
  ref.invalidate(budgetsForMonthProvider);
  ref.invalidate(spentForBudgetMonthProvider);
  // Categories
  ref.invalidate(categoryListNotifierProvider);
  ref.invalidate(categoriesByKindProvider);
  // Transfers
  ref.invalidate(transferListNotifierProvider);
  // Savings
  ref.invalidate(currentMonthSavingsProvider);
  ref.invalidate(allTimeSavingsProvider);
}
