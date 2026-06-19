import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paisa/core/errors/app_exceptions.dart';
import 'package:paisa/features/budgets/data/models/budget_model.dart';
import 'package:paisa/features/budgets/data/repositories/budget_repository.dart';
import 'package:paisa/features/budgets/presentation/providers/budget_provider.dart';
import 'package:paisa/features/expenses/data/models/expense_model.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

BudgetModel _fakeBudget({
  String id = 'b1',
  ExpenseCategory category = ExpenseCategory.foodAndDrink,
  double limitAmount = 5000.0,
  int month = 5,
  int year = 2026,
}) => BudgetModel(
      id: id,
      category: category,
      limitAmount: limitAmount,
      month: month,
      year: year,
    );

ProviderContainer _makeContainer(MockBudgetRepository mockRepo) {
  return ProviderContainer(
    overrides: [budgetRepositoryProvider.overrideWithValue(mockRepo)],
  );
}

void main() {
  late MockBudgetRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(ExpenseCategory.other);
  });

  setUp(() {
    mockRepo = MockBudgetRepository();
  });

  group('BudgetListNotifier.build', () {
    test('loads budgets for current month on build', () async {
      final budgets = [_fakeBudget(), _fakeBudget(id: 'b2', category: ExpenseCategory.transport)];
      when(
        () => mockRepo.getBudgets(
          month: any(named: 'month'),
          year: any(named: 'year'),
        ),
      ).thenAnswer((_) async => budgets);

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      final result = await container.read(budgetListNotifierProvider.future);
      expect(result, hasLength(2));
      expect(result.first.id, 'b1');
    });

    test('emits error on network failure', () async {
      when(
        () => mockRepo.getBudgets(
          month: any(named: 'month'),
          year: any(named: 'year'),
        ),
      ).thenThrow(AppException.network());

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container
          .read(budgetListNotifierProvider.future)
          .then((_) => null, onError: (_) => null);

      expect(container.read(budgetListNotifierProvider).hasError, isTrue);
    });
  });

  group('BudgetListNotifier.upsert', () {
    setUp(() {
      when(
        () => mockRepo.getBudgets(
          month: any(named: 'month'),
          year: any(named: 'year'),
        ),
      ).thenAnswer((_) async => [_fakeBudget()]);
    });

    test('prepends new budget when id is not in list', () async {
      final newBudget = _fakeBudget(id: 'b2', category: ExpenseCategory.shopping, limitAmount: 2000.0);
      when(
        () => mockRepo.upsertBudget(
          category: any(named: 'category'),
          limitAmount: any(named: 'limitAmount'),
          month: any(named: 'month'),
          year: any(named: 'year'),
        ),
      ).thenAnswer((_) async => newBudget);

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(budgetListNotifierProvider.future);
      await container.read(budgetListNotifierProvider.notifier).upsert(
            category: ExpenseCategory.shopping,
            limitAmount: 2000.0,
          );

      final state = container.read(budgetListNotifierProvider).value!;
      expect(state, hasLength(2));
      expect(state.first.id, 'b2');
    });

    test('replaces existing budget when id already in list', () async {
      final updated = _fakeBudget(id: 'b1', limitAmount: 8000.0);
      when(
        () => mockRepo.upsertBudget(
          category: any(named: 'category'),
          limitAmount: any(named: 'limitAmount'),
          month: any(named: 'month'),
          year: any(named: 'year'),
        ),
      ).thenAnswer((_) async => updated);

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(budgetListNotifierProvider.future);
      await container.read(budgetListNotifierProvider.notifier).upsert(
            category: ExpenseCategory.foodAndDrink,
            limitAmount: 8000.0,
          );

      final state = container.read(budgetListNotifierProvider).value!;
      expect(state, hasLength(1));
      expect(state.first.limitAmount, 8000.0);
    });

    test('propagates exception on server failure', () async {
      when(
        () => mockRepo.upsertBudget(
          category: any(named: 'category'),
          limitAmount: any(named: 'limitAmount'),
          month: any(named: 'month'),
          year: any(named: 'year'),
        ),
      ).thenThrow(AppException.server());

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(budgetListNotifierProvider.future);
      expect(
        () => container.read(budgetListNotifierProvider.notifier).upsert(
              category: ExpenseCategory.health,
              limitAmount: 1000.0,
            ),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('BudgetListNotifier.delete', () {
    setUp(() {
      when(
        () => mockRepo.getBudgets(
          month: any(named: 'month'),
          year: any(named: 'year'),
        ),
      ).thenAnswer(
        (_) async => [_fakeBudget(), _fakeBudget(id: 'b2', category: ExpenseCategory.transport)],
      );
    });

    test('removes budget from list by id', () async {
      when(() => mockRepo.deleteBudget('b1')).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(budgetListNotifierProvider.future);
      await container.read(budgetListNotifierProvider.notifier).delete('b1');

      final state = container.read(budgetListNotifierProvider).value!;
      expect(state, hasLength(1));
      expect(state.first.id, 'b2');
      verify(() => mockRepo.deleteBudget('b1')).called(1);
    });
  });

  group('selectedBudgetMonthProvider', () {
    test('defaults to current month', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final now = DateTime.now();
      final selected = container.read(selectedBudgetMonthProvider);
      expect(selected.year, now.year);
      expect(selected.month, now.month);
    });

    test('setMonth updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedBudgetMonthProvider.notifier).setMonth(2025, 12);
      final selected = container.read(selectedBudgetMonthProvider);
      expect(selected.year, 2025);
      expect(selected.month, 12);
    });
  });
}
