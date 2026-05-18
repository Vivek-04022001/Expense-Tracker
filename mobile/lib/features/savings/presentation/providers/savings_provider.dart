import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/savings_model.dart';
import '../../data/repositories/savings_repository.dart';

part 'savings_provider.g.dart';

@riverpod
SavingsRepository savingsRepository(SavingsRepositoryRef ref) =>
    SavingsRepository(ref.watch(dioClientProvider));

@riverpod
Future<SavingsModel> currentMonthSavings(CurrentMonthSavingsRef ref) async {
  final now = DateTime.now();
  final from = DateTime(now.year, now.month);
  final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return ref.watch(savingsRepositoryProvider).getSummary(from: from, to: to);
}

@riverpod
Future<SavingsModel> allTimeSavings(AllTimeSavingsRef ref) =>
    ref.watch(savingsRepositoryProvider).getSummary();
