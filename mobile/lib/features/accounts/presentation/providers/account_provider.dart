import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/account_model.dart';
import '../../data/repositories/account_repository.dart';

part 'account_provider.g.dart';

@riverpod
AccountRepository accountRepository(AccountRepositoryRef ref) =>
    AccountRepository(
      ref.watch(dioClientProvider),
      ref.watch(appDatabaseProvider),
      ref.watch(syncEngineProvider),
    );

@riverpod
class AccountListNotifier extends _$AccountListNotifier {
  @override
  Future<AccountsResult> build() async {
    return ref.watch(accountRepositoryProvider).getAccounts();
  }

  Future<void> create({
    required String name,
    required AccountType type,
    required double balance,
    String? color,
  }) async {
    final created = await ref.read(accountRepositoryProvider).createAccount(
          name: name,
          type: type,
          balance: balance,
          color: color,
        );
    final current = state.valueOrNull;
    final accounts = [...?current?.accounts, created];
    state = AsyncValue.data(
      AccountsResult(accounts: accounts, totalBalance: _sum(accounts)),
    );
  }

  Future<void> edit({
    required String id,
    required String name,
    required AccountType type,
    required double balance,
    String? color,
  }) async {
    final updated = await ref.read(accountRepositoryProvider).updateAccount(
          id: id,
          name: name,
          type: type,
          balance: balance,
          color: color,
        );
    final current = state.valueOrNull?.accounts ?? [];
    final accounts = [
      for (final a in current) a.id == id ? updated : a,
    ];
    state = AsyncValue.data(
      AccountsResult(accounts: accounts, totalBalance: _sum(accounts)),
    );
  }

  Future<void> delete(String id) async {
    await ref.read(accountRepositoryProvider).deleteAccount(id);
    final accounts =
        (state.valueOrNull?.accounts ?? []).where((a) => a.id != id).toList();
    state = AsyncValue.data(
      AccountsResult(accounts: accounts, totalBalance: _sum(accounts)),
    );
  }

  double _sum(List<AccountModel> accounts) =>
      accounts.fold(0.0, (sum, a) => sum + a.balance);
}
