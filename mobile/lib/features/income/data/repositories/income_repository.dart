import '../../../../core/constants/api_constants.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/sync/sync_engine.dart';
import '../datasources/income_local_datasource.dart';
import '../models/income_model.dart';

/// Offline-first income repository. Reads from Drift; writes hit the network
/// then trigger a delta sync (Phase 4 will move writes to the outbox).
class IncomeRepository {
  IncomeRepository(this._dioClient, AppDatabase db, this._sync)
      : _local = IncomeLocalDataSource(db);

  final DioClient _dioClient;
  final IncomeLocalDataSource _local;
  final SyncEngine _sync;

  Future<List<IncomeModel>> getIncomes({
    required DateTime from,
    required DateTime to,
    IncomeType? incomeType,
  }) {
    return _local.getIncomes(
      from: from,
      to: to,
      incomeType: incomeType?.toServer(),
    );
  }

  Future<IncomeModel> createIncome({
    required double amount,
    IncomeType? incomeType,
    String? description,
    String? accountId,
    String? categoryId,
  }) async {
    final response = await _dioClient.post(
      ApiConstants.income,
      data: {
        'amount': amount,
        if (incomeType != null) 'incomeType': incomeType.toServer(),
        if (description != null && description.isNotEmpty)
          'description': description,
        if (accountId != null) 'accountId': accountId,
        if (categoryId != null) 'categoryId': categoryId,
      },
    );
    await _sync.pullQuietly();
    return IncomeModel.fromJson(
      response.data['income'] as Map<String, dynamic>,
    );
  }

  Future<IncomeModel> updateIncome(
    String id, {
    double? amount,
    IncomeType? incomeType,
    String? description,
  }) async {
    final response = await _dioClient.patch(
      ApiConstants.incomeById(id),
      data: {
        if (amount != null) 'amount': amount,
        if (incomeType != null) 'incomeType': incomeType.toServer(),
        if (description != null) 'description': description,
      },
    );
    await _sync.pullQuietly();
    return IncomeModel.fromJson(
      response.data['income'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteIncome(String id) async {
    await _dioClient.delete(ApiConstants.incomeById(id));
    await _sync.pullQuietly();
  }
}
