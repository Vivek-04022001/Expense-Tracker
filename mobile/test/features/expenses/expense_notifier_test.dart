import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/core/errors/app_exceptions.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/data/repositories/expense_repository.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/expense_provider.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class FakeExpenseModel extends Fake implements ExpenseModel {}

ExpenseModel _fakeExpense({
  String id = 'e1',
  double amount = 342.50,
  ExpenseCategory category = ExpenseCategory.foodAndDrink,
  String? description = 'Swiggy',
}) => ExpenseModel(
      id: id,
      amount: amount,
      category: category,
      paymentMethod: ExpensePaymentMethod.upi,
      userId: 'u1',
      createdAt: DateTime(2026, 5, 18, 10),
      description: description,
    );

ProviderContainer _makeContainer(MockExpenseRepository mockRepo) {
  return ProviderContainer(
    overrides: [
      expenseRepositoryProvider.overrideWithValue(mockRepo),
    ],
  );
}

void main() {
  late MockExpenseRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(FakeExpenseModel());
  });

  setUp(() {
    mockRepo = MockExpenseRepository();
  });

  group('ExpenseListNotifier.build', () {
    test('loads current month expenses on build', () async {
      final expenses = [_fakeExpense(), _fakeExpense(id: 'e2', amount: 100.0)];
      when(
        () => mockRepo.getExpenses(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => expenses);

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      final result = await container.read(expenseListNotifierProvider.future);
      expect(result, hasLength(2));
      expect(result.first.id, 'e1');
    });

    test('emits error state on network failure', () async {
      when(
        () => mockRepo.getExpenses(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenThrow(AppException.network());

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      final state = await container.read(expenseListNotifierProvider.future).then(
            (_) => null,
            onError: (_) => null,
          );
      expect(state, isNull);
      expect(container.read(expenseListNotifierProvider).hasError, isTrue);
    });
  });

  group('ExpenseListNotifier.create', () {
    setUp(() {
      when(
        () => mockRepo.getExpenses(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => [_fakeExpense()]);
    });

    test('prepends new expense to list', () async {
      final newExpense = _fakeExpense(id: 'e2', amount: 50.0, description: 'Tea');
      when(
        () => mockRepo.createExpense(
          amount: any(named: 'amount'),
          description: any(named: 'description'),
          category: any(named: 'category'),
          paymentMethod: any(named: 'paymentMethod'),
        ),
      ).thenAnswer((_) async => newExpense);

      when(() => mockRepo.getExpenseSummary()).thenAnswer((_) async => throw UnimplementedError());

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(expenseListNotifierProvider.future);
      await container.read(expenseListNotifierProvider.notifier).create(
            amount: 50.0,
            description: 'Tea',
            category: ExpenseCategory.foodAndDrink,
            paymentMethod: ExpensePaymentMethod.cash,
          );

      final state = container.read(expenseListNotifierProvider).value!;
      expect(state, hasLength(2));
      expect(state.first.id, 'e2');
    });

    test('rethrows AppException on create failure', () async {
      when(
        () => mockRepo.createExpense(
          amount: any(named: 'amount'),
          description: any(named: 'description'),
          category: any(named: 'category'),
          paymentMethod: any(named: 'paymentMethod'),
        ),
      ).thenThrow(AppException.server());

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(expenseListNotifierProvider.future);
      expect(
        () => container.read(expenseListNotifierProvider.notifier).create(amount: 50.0),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('ExpenseListNotifier.delete', () {
    setUp(() {
      when(
        () => mockRepo.getExpenses(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => [_fakeExpense(), _fakeExpense(id: 'e2', amount: 100.0)]);
    });

    test('removes expense from list by id', () async {
      when(() => mockRepo.deleteExpense('e1')).thenAnswer((_) async {});
      when(() => mockRepo.getExpenseSummary()).thenAnswer((_) async => throw UnimplementedError());

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(expenseListNotifierProvider.future);
      await container.read(expenseListNotifierProvider.notifier).delete('e1');

      final state = container.read(expenseListNotifierProvider).value!;
      expect(state, hasLength(1));
      expect(state.first.id, 'e2');
      verify(() => mockRepo.deleteExpense('e1')).called(1);
    });
  });

  group('ExpenseListNotifier.edit', () {
    setUp(() {
      when(
        () => mockRepo.getExpenses(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => [_fakeExpense(), _fakeExpense(id: 'e2', amount: 100.0)]);
    });

    test('replaces updated expense in list', () async {
      final updated = _fakeExpense(
        id: 'e1',
        amount: 999.0,
        category: ExpenseCategory.shopping,
      );
      when(
        () => mockRepo.updateExpense(
          'e1',
          amount: any(named: 'amount'),
          category: any(named: 'category'),
        ),
      ).thenAnswer((_) async => updated);
      when(() => mockRepo.getExpenseSummary()).thenAnswer((_) async => throw UnimplementedError());

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(expenseListNotifierProvider.future);
      await container.read(expenseListNotifierProvider.notifier).edit(
            'e1',
            amount: 999.0,
            category: ExpenseCategory.shopping,
          );

      final state = container.read(expenseListNotifierProvider).value!;
      expect(state.first.amount, 999.0);
      expect(state.first.category, ExpenseCategory.shopping);
      expect(state, hasLength(2));
    });
  });

  group('selectedExpenseMonthProvider', () {
    test('defaults to current month', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final now = DateTime.now();
      final selected = container.read(selectedExpenseMonthProvider);
      expect(selected.year, now.year);
      expect(selected.month, now.month);
    });

    test('setMonth updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedExpenseMonthProvider.notifier).setMonth(2026, 3);
      final selected = container.read(selectedExpenseMonthProvider);
      expect(selected.year, 2026);
      expect(selected.month, 3);
    });
  });
}
