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
String _$incomeListNotifierHash() =>
    r'def93911b8012b67198e884973af96eef8a47a4f';

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
