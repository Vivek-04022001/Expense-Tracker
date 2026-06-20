import '../../../../core/constants/api_constants.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/sync/sync_engine.dart';
import '../datasources/transfer_local_datasource.dart';
import '../models/transfer_model.dart';

/// Offline-first transfer repository. Reads from Drift; writes hit the network
/// then trigger a delta sync.
class TransferRepository {
  TransferRepository(this._dioClient, AppDatabase db, this._sync)
      : _local = TransferLocalDataSource(db);

  final DioClient _dioClient;
  final TransferLocalDataSource _local;
  final SyncEngine _sync;

  Future<List<TransferModel>> getTransfers() => _local.getTransfers();

  Future<TransferModel> createTransfer({
    required double amount,
    required String fromAccountId,
    required String toAccountId,
    String? description,
  }) async {
    final response = await _dioClient.post(
      ApiConstants.transfers,
      data: {
        'amount': amount,
        'fromAccountId': fromAccountId,
        'toAccountId': toAccountId,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    await _sync.pullQuietly();
    return TransferModel.fromJson(
      response.data['transfer'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteTransfer(String id) async {
    await _dioClient.delete(ApiConstants.transferById(id));
    await _sync.pullQuietly();
  }
}
