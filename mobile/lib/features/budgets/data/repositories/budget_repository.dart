import '../../../../core/constants/api_constants.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../datasources/budget_local_datasource.dart';
import '../models/budget_model.dart';

/// Offline-first budget repository. Reads and status come from Drift; writes hit
/// the network then trigger a delta sync.
class BudgetRepository {
  BudgetRepository(this._dioClient, AppDatabase db, this._sync)
      : _local = BudgetLocalDataSource(db);

  final DioClient _dioClient;
  final BudgetLocalDataSource _local;
  final SyncEngine _sync;

  Future<List<BudgetModel>> getBudgets({
    required int month,
    required int year,
  }) {
    return _local.getBudgets(month: month, year: year);
  }

  Future<BudgetModel> upsertBudget({
    required ExpenseCategory category,
    required double limitAmount,
    required int month,
    required int year,
  }) async {
    final response = await _dioClient.put(
      ApiConstants.budgets,
      data: {
        'category': category.toServer(),
        'limitAmount': limitAmount,
        'month': month,
        'year': year,
      },
    );
    await _sync.pullQuietly();
    return BudgetModel.fromJson(response.data['budget'] as Map<String, dynamic>);
  }

  Future<void> deleteBudget(String id) async {
    await _dioClient.delete(ApiConstants.budgetById(id));
    await _sync.pullQuietly();
  }

  Future<BudgetStatusModel> getBudgetStatus(String id) async {
    final status = await _local.getBudgetStatus(id);
    if (status == null) {
      throw StateError('Budget not found: $id');
    }
    return status;
  }
}
