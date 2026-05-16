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
String _$expenseSummaryHash() => r'fd37076acff544ad473c115ec7c6cfa678601af2';

/// See also [expenseSummary].
@ProviderFor(expenseSummary)
final expenseSummaryProvider =
    AutoDisposeFutureProvider<ExpenseSummary>.internal(
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
typedef ExpenseSummaryRef = AutoDisposeFutureProviderRef<ExpenseSummary>;
String _$expenseListNotifierHash() =>
    r'c38dcd0b3fef69f831960b053d770c2ad0680cf7';

/// See also [ExpenseListNotifier].
@ProviderFor(ExpenseListNotifier)
final expenseListNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      ExpenseListNotifier,
      ExpenseListResponse
    >.internal(
      ExpenseListNotifier.new,
      name: r'expenseListNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$expenseListNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ExpenseListNotifier = AutoDisposeAsyncNotifier<ExpenseListResponse>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
