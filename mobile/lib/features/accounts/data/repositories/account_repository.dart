import '../../../../core/constants/api_constants.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/sync/sync_engine.dart';
import '../datasources/account_local_datasource.dart';
import '../models/account_model.dart';

class AccountsResult {
  const AccountsResult({required this.accounts, required this.totalBalance});

  final List<AccountModel> accounts;
  final double totalBalance;
}

/// Offline-first account repository. Reads (and the derived total balance) come
/// from Drift; writes hit the network then trigger a delta sync.
class AccountRepository {
  AccountRepository(this._dioClient, AppDatabase db, this._sync)
      : _local = AccountLocalDataSource(db);

  final DioClient _dioClient;
  final AccountLocalDataSource _local;
  final SyncEngine _sync;

  Future<AccountsResult> getAccounts() async {
    final accounts = await _local.getAccounts();
    final total = accounts.fold<double>(0, (sum, a) => sum + a.balance);
    return AccountsResult(accounts: accounts, totalBalance: total);
  }

  Future<AccountModel> createAccount({
    required String name,
    required AccountType type,
    required double balance,
    String? color,
  }) async {
    final response = await _dioClient.post(
      ApiConstants.accounts,
      data: {
        'name': name,
        'type': type.toServer(),
        'balance': balance,
        if (color != null) 'color': color,
      },
    );
    await _sync.pullQuietly();
    return AccountModel.fromJson(
        response.data['account'] as Map<String, dynamic>);
  }

  Future<AccountModel> updateAccount({
    required String id,
    required String name,
    required AccountType type,
    required double balance,
    String? color,
  }) async {
    final response = await _dioClient.put(
      ApiConstants.accountById(id),
      data: {
        'name': name,
        'type': type.toServer(),
        'balance': balance,
        if (color != null) 'color': color,
      },
    );
    await _sync.pullQuietly();
    return AccountModel.fromJson(
        response.data['account'] as Map<String, dynamic>);
  }

  Future<void> deleteAccount(String id) async {
    await _dioClient.delete(ApiConstants.accountById(id));
    await _sync.pullQuietly();
  }
}
