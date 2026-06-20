// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$budgetRepositoryHash() => r'ed33fe85e3b843254b3b346a5e18119777003dc3';

/// See also [budgetRepository].
@ProviderFor(budgetRepository)
final budgetRepositoryProvider = AutoDisposeProvider<BudgetRepository>.internal(
  budgetRepository,
  name: r'budgetRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$budgetRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BudgetRepositoryRef = AutoDisposeProviderRef<BudgetRepository>;
String _$budgetsForMonthHash() => r'f57ddbf565b8eb6c71cf15aaca341ce71070b410';

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

/// See also [budgetsForMonth].
@ProviderFor(budgetsForMonth)
const budgetsForMonthProvider = BudgetsForMonthFamily();

/// See also [budgetsForMonth].
class BudgetsForMonthFamily extends Family<AsyncValue<List<BudgetModel>>> {
  /// See also [budgetsForMonth].
  const BudgetsForMonthFamily();

  /// See also [budgetsForMonth].
  BudgetsForMonthProvider call(DateTime month) {
    return BudgetsForMonthProvider(month);
  }

  @override
  BudgetsForMonthProvider getProviderOverride(
    covariant BudgetsForMonthProvider provider,
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
  String? get name => r'budgetsForMonthProvider';
}

/// See also [budgetsForMonth].
class BudgetsForMonthProvider
    extends AutoDisposeFutureProvider<List<BudgetModel>> {
  /// See also [budgetsForMonth].
  BudgetsForMonthProvider(DateTime month)
    : this._internal(
        (ref) => budgetsForMonth(ref as BudgetsForMonthRef, month),
        from: budgetsForMonthProvider,
        name: r'budgetsForMonthProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$budgetsForMonthHash,
        dependencies: BudgetsForMonthFamily._dependencies,
        allTransitiveDependencies:
            BudgetsForMonthFamily._allTransitiveDependencies,
        month: month,
      );

  BudgetsForMonthProvider._internal(
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
    FutureOr<List<BudgetModel>> Function(BudgetsForMonthRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BudgetsForMonthProvider._internal(
        (ref) => create(ref as BudgetsForMonthRef),
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
  AutoDisposeFutureProviderElement<List<BudgetModel>> createElement() {
    return _BudgetsForMonthProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BudgetsForMonthProvider && other.month == month;
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
mixin BudgetsForMonthRef on AutoDisposeFutureProviderRef<List<BudgetModel>> {
  /// The parameter `month` of this provider.
  DateTime get month;
}

class _BudgetsForMonthProviderElement
    extends AutoDisposeFutureProviderElement<List<BudgetModel>>
    with BudgetsForMonthRef {
  _BudgetsForMonthProviderElement(super.provider);

  @override
  DateTime get month => (origin as BudgetsForMonthProvider).month;
}

String _$spentForBudgetMonthHash() =>
    r'1783955ce53f7804f0bf42385693dd286e9873c5';

/// Derives spent-per-category for a given month from the expense summary.
/// Avoids N+1 API calls (one summary call covers all categories & months).
///
/// Copied from [spentForBudgetMonth].
@ProviderFor(spentForBudgetMonth)
const spentForBudgetMonthProvider = SpentForBudgetMonthFamily();

/// Derives spent-per-category for a given month from the expense summary.
/// Avoids N+1 API calls (one summary call covers all categories & months).
///
/// Copied from [spentForBudgetMonth].
class SpentForBudgetMonthFamily
    extends Family<AsyncValue<Map<ExpenseCategory, double>>> {
  /// Derives spent-per-category for a given month from the expense summary.
  /// Avoids N+1 API calls (one summary call covers all categories & months).
  ///
  /// Copied from [spentForBudgetMonth].
  const SpentForBudgetMonthFamily();

  /// Derives spent-per-category for a given month from the expense summary.
  /// Avoids N+1 API calls (one summary call covers all categories & months).
  ///
  /// Copied from [spentForBudgetMonth].
  SpentForBudgetMonthProvider call(DateTime month) {
    return SpentForBudgetMonthProvider(month);
  }

  @override
  SpentForBudgetMonthProvider getProviderOverride(
    covariant SpentForBudgetMonthProvider provider,
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
  String? get name => r'spentForBudgetMonthProvider';
}

/// Derives spent-per-category for a given month from the expense summary.
/// Avoids N+1 API calls (one summary call covers all categories & months).
///
/// Copied from [spentForBudgetMonth].
class SpentForBudgetMonthProvider
    extends AutoDisposeFutureProvider<Map<ExpenseCategory, double>> {
  /// Derives spent-per-category for a given month from the expense summary.
  /// Avoids N+1 API calls (one summary call covers all categories & months).
  ///
  /// Copied from [spentForBudgetMonth].
  SpentForBudgetMonthProvider(DateTime month)
    : this._internal(
        (ref) => spentForBudgetMonth(ref as SpentForBudgetMonthRef, month),
        from: spentForBudgetMonthProvider,
        name: r'spentForBudgetMonthProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$spentForBudgetMonthHash,
        dependencies: SpentForBudgetMonthFamily._dependencies,
        allTransitiveDependencies:
            SpentForBudgetMonthFamily._allTransitiveDependencies,
        month: month,
      );

  SpentForBudgetMonthProvider._internal(
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
    FutureOr<Map<ExpenseCategory, double>> Function(
      SpentForBudgetMonthRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SpentForBudgetMonthProvider._internal(
        (ref) => create(ref as SpentForBudgetMonthRef),
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
  AutoDisposeFutureProviderElement<Map<ExpenseCategory, double>>
  createElement() {
    return _SpentForBudgetMonthProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SpentForBudgetMonthProvider && other.month == month;
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
mixin SpentForBudgetMonthRef
    on AutoDisposeFutureProviderRef<Map<ExpenseCategory, double>> {
  /// The parameter `month` of this provider.
  DateTime get month;
}

class _SpentForBudgetMonthProviderElement
    extends AutoDisposeFutureProviderElement<Map<ExpenseCategory, double>>
    with SpentForBudgetMonthRef {
  _SpentForBudgetMonthProviderElement(super.provider);

  @override
  DateTime get month => (origin as SpentForBudgetMonthProvider).month;
}

String _$selectedBudgetMonthHash() =>
    r'fd7cfaaf5c6d39e51050ee06c7f5e668776da25e';

/// See also [SelectedBudgetMonth].
@ProviderFor(SelectedBudgetMonth)
final selectedBudgetMonthProvider =
    AutoDisposeNotifierProvider<SelectedBudgetMonth, DateTime>.internal(
      SelectedBudgetMonth.new,
      name: r'selectedBudgetMonthProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$selectedBudgetMonthHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SelectedBudgetMonth = AutoDisposeNotifier<DateTime>;
String _$budgetListNotifierHash() =>
    r'511491e52c9fb8266a7e9771881c8eccf43c41b6';

/// See also [BudgetListNotifier].
@ProviderFor(BudgetListNotifier)
final budgetListNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      BudgetListNotifier,
      List<BudgetModel>
    >.internal(
      BudgetListNotifier.new,
      name: r'budgetListNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$budgetListNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BudgetListNotifier = AutoDisposeAsyncNotifier<List<BudgetModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
