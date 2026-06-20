import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paisa/core/db/app_database.dart';
import 'package:paisa/core/errors/app_exceptions.dart';
import 'package:paisa/features/income/data/models/income_model.dart';
import 'package:paisa/features/income/data/repositories/income_repository.dart';
import 'package:paisa/features/income/presentation/providers/income_provider.dart';

class MockIncomeRepository extends Mock implements IncomeRepository {}

class FakeIncomeModel extends Fake implements IncomeModel {}

IncomeModel _fakeIncome({
  String id = 'i1',
  double amount = 50000.0,
  IncomeType incomeType = IncomeType.salary,
  String? description = 'May salary',
}) => IncomeModel(
      id: id,
      amount: amount,
      incomeType: incomeType,
      userId: 'u1',
      createdAt: DateTime(2026, 5, 18, 10),
      description: description,
    );

ProviderContainer _makeContainer(MockIncomeRepository mockRepo) {
  // In-memory DB backs related providers (savings, accounts) invalidated on write.
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return ProviderContainer(
    overrides: [
      incomeRepositoryProvider.overrideWithValue(mockRepo),
      appDatabaseProvider.overrideWithValue(db),
    ],
  );
}

void main() {
  late MockIncomeRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(FakeIncomeModel());
  });

  setUp(() {
    mockRepo = MockIncomeRepository();
  });

  group('IncomeListNotifier.build', () {
    test('loads current month incomes on build', () async {
      when(
        () => mockRepo.getIncomes(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => [_fakeIncome(), _fakeIncome(id: 'i2', amount: 10000.0)]);

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      final result = await container.read(incomeListNotifierProvider.future);
      expect(result, hasLength(2));
      expect(result.first.id, 'i1');
    });

    test('emits error state on network failure', () async {
      when(
        () => mockRepo.getIncomes(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenThrow(AppException.network());

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(incomeListNotifierProvider.future).then(
            (_) => null,
            onError: (_) => null,
          );
      expect(container.read(incomeListNotifierProvider).hasError, isTrue);
    });
  });

  group('IncomeListNotifier.create', () {
    setUp(() {
      when(
        () => mockRepo.getIncomes(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => [_fakeIncome()]);
    });

    test('prepends new income to list', () async {
      final newIncome = _fakeIncome(id: 'i2', amount: 5000.0, description: 'Freelance gig');
      when(
        () => mockRepo.createIncome(
          amount: any(named: 'amount'),
          incomeType: any(named: 'incomeType'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async => newIncome);

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(incomeListNotifierProvider.future);
      await container.read(incomeListNotifierProvider.notifier).create(
            amount: 5000.0,
            incomeType: IncomeType.freelance,
            description: 'Freelance gig',
          );

      final state = container.read(incomeListNotifierProvider).value!;
      expect(state, hasLength(2));
      expect(state.first.id, 'i2');
    });

    test('throws AppException on create failure', () async {
      when(
        () => mockRepo.createIncome(
          amount: any(named: 'amount'),
          incomeType: any(named: 'incomeType'),
          description: any(named: 'description'),
        ),
      ).thenThrow(AppException.server());

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(incomeListNotifierProvider.future);
      expect(
        () => container.read(incomeListNotifierProvider.notifier).create(amount: 100.0),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('IncomeListNotifier.delete', () {
    setUp(() {
      when(
        () => mockRepo.getIncomes(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer(
        (_) async => [_fakeIncome(), _fakeIncome(id: 'i2', amount: 10000.0)],
      );
    });

    test('removes income from list by id', () async {
      when(() => mockRepo.deleteIncome('i1')).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(incomeListNotifierProvider.future);
      await container.read(incomeListNotifierProvider.notifier).delete('i1');

      final state = container.read(incomeListNotifierProvider).value!;
      expect(state, hasLength(1));
      expect(state.first.id, 'i2');
      verify(() => mockRepo.deleteIncome('i1')).called(1);
    });
  });

  group('IncomeListNotifier.edit', () {
    setUp(() {
      when(
        () => mockRepo.getIncomes(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer(
        (_) async => [_fakeIncome(), _fakeIncome(id: 'i2', amount: 10000.0)],
      );
    });

    test('replaces updated income in list', () async {
      final updated = _fakeIncome(id: 'i1', amount: 60000.0, incomeType: IncomeType.investment);
      when(
        () => mockRepo.updateIncome(
          'i1',
          amount: any(named: 'amount'),
          incomeType: any(named: 'incomeType'),
        ),
      ).thenAnswer((_) async => updated);

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(incomeListNotifierProvider.future);
      await container.read(incomeListNotifierProvider.notifier).edit(
            'i1',
            amount: 60000.0,
            incomeType: IncomeType.investment,
          );

      final state = container.read(incomeListNotifierProvider).value!;
      expect(state.first.amount, 60000.0);
      expect(state.first.incomeType, IncomeType.investment);
    });
  });

  group('SelectedIncomeMonth', () {
    test('defaults to current month', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final now = DateTime.now();
      final selected = container.read(selectedIncomeMonthProvider);
      expect(selected.year, now.year);
      expect(selected.month, now.month);
    });

    test('setMonth updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedIncomeMonthProvider.notifier).setMonth(2026, 2);
      final selected = container.read(selectedIncomeMonthProvider);
      expect(selected.year, 2026);
      expect(selected.month, 2);
    });
  });
}
