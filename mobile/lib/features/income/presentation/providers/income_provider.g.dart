// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'income_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$incomeRepositoryHash() => r'4d1383af342221b524af0b843ad4e28167cb9ec7';

/// See also [incomeRepository].
@ProviderFor(incomeRepository)
final incomeRepositoryProvider = AutoDisposeProvider<IncomeRepository>.internal(
  incomeRepository,
  name: r'incomeRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$incomeRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IncomeRepositoryRef = AutoDisposeProviderRef<IncomeRepository>;
String _$currentMonthIncomesHash() =>
    r'7937c1c3d5e5dfd1d956c59568f0382a153f722c';

/// See also [currentMonthIncomes].
@ProviderFor(currentMonthIncomes)
final currentMonthIncomesProvider =
    AutoDisposeFutureProvider<List<IncomeModel>>.internal(
      currentMonthIncomes,
      name: r'currentMonthIncomesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentMonthIncomesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentMonthIncomesRef =
    AutoDisposeFutureProviderRef<List<IncomeModel>>;
String _$incomesForMonthHash() => r'd99b730466321d123792f69234229bd3e3c7adbf';

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

/// See also [incomesForMonth].
@ProviderFor(incomesForMonth)
const incomesForMonthProvider = IncomesForMonthFamily();

/// See also [incomesForMonth].
class IncomesForMonthFamily extends Family<AsyncValue<List<IncomeModel>>> {
  /// See also [incomesForMonth].
  const IncomesForMonthFamily();

  /// See also [incomesForMonth].
  IncomesForMonthProvider call(DateTime month) {
    return IncomesForMonthProvider(month);
  }

  @override
  IncomesForMonthProvider getProviderOverride(
    covariant IncomesForMonthProvider provider,
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
  String? get name => r'incomesForMonthProvider';
}

/// See also [incomesForMonth].
class IncomesForMonthProvider
    extends AutoDisposeFutureProvider<List<IncomeModel>> {
  /// See also [incomesForMonth].
  IncomesForMonthProvider(DateTime month)
    : this._internal(
        (ref) => incomesForMonth(ref as IncomesForMonthRef, month),
        from: incomesForMonthProvider,
        name: r'incomesForMonthProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$incomesForMonthHash,
        dependencies: IncomesForMonthFamily._dependencies,
        allTransitiveDependencies:
            IncomesForMonthFamily._allTransitiveDependencies,
        month: month,
      );

  IncomesForMonthProvider._internal(
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
    FutureOr<List<IncomeModel>> Function(IncomesForMonthRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IncomesForMonthProvider._internal(
        (ref) => create(ref as IncomesForMonthRef),
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
  AutoDisposeFutureProviderElement<List<IncomeModel>> createElement() {
    return _IncomesForMonthProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IncomesForMonthProvider && other.month == month;
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
mixin IncomesForMonthRef on AutoDisposeFutureProviderRef<List<IncomeModel>> {
  /// The parameter `month` of this provider.
  DateTime get month;
}

class _IncomesForMonthProviderElement
    extends AutoDisposeFutureProviderElement<List<IncomeModel>>
    with IncomesForMonthRef {
  _IncomesForMonthProviderElement(super.provider);

  @override
  DateTime get month => (origin as IncomesForMonthProvider).month;
}

String _$incomeListNotifierHash() =>
    r'ff8f86daef0766e404df0b1297bc500af9d17537';

/// See also [IncomeListNotifier].
@ProviderFor(IncomeListNotifier)
final incomeListNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      IncomeListNotifier,
      List<IncomeModel>
    >.internal(
      IncomeListNotifier.new,
      name: r'incomeListNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$incomeListNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$IncomeListNotifier = AutoDisposeAsyncNotifier<List<IncomeModel>>;
String _$selectedIncomeMonthHash() =>
    r'7fe6482e9b3d898135ffcf40242598ebd88acea2';

/// See also [SelectedIncomeMonth].
@ProviderFor(SelectedIncomeMonth)
final selectedIncomeMonthProvider =
    AutoDisposeNotifierProvider<SelectedIncomeMonth, DateTime>.internal(
      SelectedIncomeMonth.new,
      name: r'selectedIncomeMonthProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$selectedIncomeMonthHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SelectedIncomeMonth = AutoDisposeNotifier<DateTime>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
