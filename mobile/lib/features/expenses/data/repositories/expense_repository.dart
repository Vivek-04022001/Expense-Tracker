import '../../../../core/constants/api_constants.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/sync/sync_engine.dart';
import '../datasources/expense_local_datasource.dart';
import '../models/expense_model.dart';
import '../models/expense_summary_model.dart';

/// Offline-first expense repository.
///
/// Reads come from the local Drift database (instant, works offline). Writes
/// still go to the network in this phase, then trigger a delta sync so the
/// local copy — including recomputed account balances — stays current.
/// Phase 4 will flip writes to local-first via the outbox.
class ExpenseRepository {
  ExpenseRepository(this._dioClient, AppDatabase db, this._sync)
      : _local = ExpenseLocalDataSource(db);

  final DioClient _dioClient;
  final ExpenseLocalDataSource _local;
  final SyncEngine _sync;

  Future<List<ExpenseModel>> getExpenses({
    required DateTime from,
    required DateTime to,
    String? category,
  }) {
    return _local.getExpenses(from: from, to: to, category: category);
  }

  Future<ExpenseModel> createExpense({
    required double amount,
    String? description,
    ExpenseCategory? category,
    ExpensePaymentMethod? paymentMethod,
    String? accountId,
    String? categoryId,
  }) async {
    final response = await _dioClient.post(
      ApiConstants.expenses,
      data: {
        'amount': amount,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (category != null) 'category': category.toServer(),
        if (paymentMethod != null) 'paymentMethod': paymentMethod.toServer(),
        if (accountId != null) 'accountId': accountId,
        if (categoryId != null) 'categoryId': categoryId,
      },
    );
    await _sync.pullQuietly();
    return ExpenseModel.fromJson(
      response.data['expense'] as Map<String, dynamic>,
    );
  }

  Future<ExpenseModel> updateExpense(
    String id, {
    double? amount,
    String? description,
    ExpenseCategory? category,
    ExpensePaymentMethod? paymentMethod,
  }) async {
    final response = await _dioClient.put(
      ApiConstants.expenseById(id),
      data: {
        if (amount != null) 'amount': amount,
        if (description != null) 'description': description,
        if (category != null) 'category': category.toServer(),
        if (paymentMethod != null) 'paymentMethod': paymentMethod.toServer(),
      },
    );
    await _sync.pullQuietly();
    return ExpenseModel.fromJson(
      response.data['expense'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteExpense(String id) async {
    await _dioClient.delete(ApiConstants.expenseById(id));
    await _sync.pullQuietly();
  }

  Future<ExpenseSummaryModel> getExpenseSummary() => _local.getSummary();
}
