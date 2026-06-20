import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/transfer_model.dart';
import '../../data/repositories/transfer_repository.dart';

part 'transfer_provider.g.dart';

@riverpod
TransferRepository transferRepository(TransferRepositoryRef ref) =>
    TransferRepository(
      ref.watch(dioClientProvider),
      ref.watch(appDatabaseProvider),
      ref.watch(syncEngineProvider),
    );

@riverpod
class TransferListNotifier extends _$TransferListNotifier {
  @override
  Future<List<TransferModel>> build() async {
    return ref.watch(transferRepositoryProvider).getTransfers();
  }

  Future<void> create({
    required double amount,
    required String fromAccountId,
    required String toAccountId,
    String? description,
  }) async {
    final created = await ref.read(transferRepositoryProvider).createTransfer(
          amount: amount,
          fromAccountId: fromAccountId,
          toAccountId: toAccountId,
          description: description,
        );
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([created, ...current]);
    // A transfer moves money between accounts — refresh balances.
    ref.invalidate(accountListNotifierProvider);
  }

  Future<void> delete(String id) async {
    await ref.read(transferRepositoryProvider).deleteTransfer(id);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((t) => t.id != id).toList());
    ref.invalidate(accountListNotifierProvider);
  }
}
