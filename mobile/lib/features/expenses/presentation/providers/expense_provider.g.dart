// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$expenseRepositoryHash() => r'1012db1a0a332446c1d55ce9f4cf0d894478857f';

/// See also [expenseRepository].
@ProviderFor(expenseRepository)
final expenseRepositoryProvider =
    AutoDisposeProvider<ExpenseRepository>.internal(
      expenseRepository,
      name: r'expenseRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$expenseRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ExpenseRepositoryRef = AutoDisposeProviderRef<ExpenseRepository>;
String _$expenseSummaryHash() => r'47e15074ba88b4f3cc196a532cad03e2c97b0ab2';

/// See also [expenseSummary].
@ProviderFor(expenseSummary)
final expenseSummaryProvider =
    AutoDisposeFutureProvider<ExpenseSummaryModel>.internal(
      expenseSummary,
      name: r'expenseSummaryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$expenseSummaryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ExpenseSummaryRef = AutoDisposeFutureProviderRef<ExpenseSummaryModel>;
String _$currentMonthExpensesHash() =>
    r'cfd9da35eaacb1f14a9e7b83f0d846da8e3a4de1';

/// See also [currentMonthExpenses].
@ProviderFor(currentMonthExpenses)
final currentMonthExpensesProvider =
    AutoDisposeFutureProvider<List<ExpenseModel>>.internal(
      currentMonthExpenses,
      name: r'currentMonthExpensesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentMonthExpensesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentMonthExpensesRef =
    AutoDisposeFutureProviderRef<List<ExpenseModel>>;
String _$expensesForMonthHash() => r'116b092d7ac8a5649374ba6b6a0e2b88434c3b8b';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [expensesForMonth].
@ProviderFor(expensesForMonth)
const expensesForMonthProvider = ExpensesForMonthFamily();

/// See also [expensesForMonth].
class ExpensesForMonthFamily extends Family<AsyncValue<List<ExpenseModel>>> {
  /// See also [expensesForMonth].
  const ExpensesForMonthFamily();

  /// See also [expensesForMonth].
  ExpensesForMonthProvider call(DateTime month) {
    return ExpensesForMonthProvider(month);
  }

  @override
  ExpensesForMonthProvider getProviderOverride(
    covariant ExpensesForMonthProvider provider,
  ) {
    return call(provider.month);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'expensesForMonthProvider';
}

/// See also [expensesForMonth].
class ExpensesForMonthProvider
    extends AutoDisposeFutureProvider<List<ExpenseModel>> {
  /// See also [expensesForMonth].
  ExpensesForMonthProvider(DateTime month)
    : this._internal(
        (ref) => expensesForMonth(ref as ExpensesForMonthRef, month),
        from: expensesForMonthProvider,
        name: r'expensesForMonthProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$expensesForMonthHash,
        dependencies: ExpensesForMonthFamily._dependencies,
        allTransitiveDependencies:
            ExpensesForMonthFamily._allTransitiveDependencies,
        month: month,
      );

  ExpensesForMonthProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.month,
  }) : super.internal();

  final DateTime month;

  @override
  Override overrideWith(
    FutureOr<List<ExpenseModel>> Function(ExpensesForMonthRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ExpensesForMonthProvider._internal(
        (ref) => create(ref as ExpensesForMonthRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        month: month,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ExpenseModel>> createElement() {
    return _ExpensesForMonthProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ExpensesForMonthProvider && other.month == month;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ExpensesForMonthRef on AutoDisposeFutureProviderRef<List<ExpenseModel>> {
  /// The parameter `month` of this provider.
  DateTime get month;
}

class _ExpensesForMonthProviderElement
    extends AutoDisposeFutureProviderElement<List<ExpenseModel>>
    with ExpensesForMonthRef {
  _ExpensesForMonthProviderElement(super.provider);

  @override
  DateTime get month => (origin as ExpensesForMonthProvider).month;
}

String _$selectedExpenseMonthHash() =>
    r'874218d473bb21ffbf2c9c3af7120d8e14426abf';

/// See also [SelectedExpenseMonth].
@ProviderFor(SelectedExpenseMonth)
final selectedExpenseMonthProvider =
    AutoDisposeNotifierProvider<SelectedExpenseMonth, DateTime>.internal(
      SelectedExpenseMonth.new,
      name: r'selectedExpenseMonthProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$selectedExpenseMonthHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SelectedExpenseMonth = AutoDisposeNotifier<DateTime>;
String _$expenseListNotifierHash() =>
    r'f338dc8942393db66dd19e2f6b8e3e11f7ae330a';

/// See also [ExpenseListNotifier].
@ProviderFor(ExpenseListNotifier)
final expenseListNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      ExpenseListNotifier,
      List<ExpenseModel>
    >.internal(
      ExpenseListNotifier.new,
      name: r'expenseListNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$expenseListNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ExpenseListNotifier = AutoDisposeAsyncNotifier<List<ExpenseModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
