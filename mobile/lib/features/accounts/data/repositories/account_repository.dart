import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/account_model.dart';

class AccountsResult {
  const AccountsResult({required this.accounts, required this.totalBalance});

  final List<AccountModel> accounts;
  final double totalBalance;
}

class AccountRepository {
  final DioClient _dioClient;

  AccountRepository(this._dioClient);

  Future<AccountsResult> getAccounts() async {
    final response = await _dioClient.get(ApiConstants.accounts);
    final accounts = (response.data['accounts'] as List)
        .cast<Map<String, dynamic>>()
        .map(AccountModel.fromJson)
        .toList();
    final total = double.parse((response.data['totalBalance'] ?? 0).toString());
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
    return AccountModel.fromJson(response.data['account'] as Map<String, dynamic>);
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
    return AccountModel.fromJson(response.data['account'] as Map<String, dynamic>);
  }

  Future<void> deleteAccount(String id) async {
    await _dioClient.delete(ApiConstants.accountById(id));
  }
}
