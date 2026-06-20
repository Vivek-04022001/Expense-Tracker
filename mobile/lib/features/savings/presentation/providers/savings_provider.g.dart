// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'savings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$savingsRepositoryHash() => r'66168270cbd5270ab584c0acdd9e509a68011cd0';

/// See also [savingsRepository].
@ProviderFor(savingsRepository)
final savingsRepositoryProvider =
    AutoDisposeProvider<SavingsRepository>.internal(
      savingsRepository,
      name: r'savingsRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$savingsRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SavingsRepositoryRef = AutoDisposeProviderRef<SavingsRepository>;
String _$currentMonthSavingsHash() =>
    r'659b04285c40b724b2838190e703369828191f43';

/// See also [currentMonthSavings].
@ProviderFor(currentMonthSavings)
final currentMonthSavingsProvider =
    AutoDisposeFutureProvider<SavingsModel>.internal(
      currentMonthSavings,
      name: r'currentMonthSavingsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentMonthSavingsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentMonthSavingsRef = AutoDisposeFutureProviderRef<SavingsModel>;
String _$allTimeSavingsHash() => r'a43725572ef7222de6caca7d5be0e6d94cdfd479';

/// See also [allTimeSavings].
@ProviderFor(allTimeSavings)
final allTimeSavingsProvider = AutoDisposeFutureProvider<SavingsModel>.internal(
  allTimeSavings,
  name: r'allTimeSavingsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allTimeSavingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllTimeSavingsRef = AutoDisposeFutureProviderRef<SavingsModel>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
