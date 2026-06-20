// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$accountRepositoryHash() => r'6df0aa88934fae2a9510e7174901abc4485f912c';

/// See also [accountRepository].
@ProviderFor(accountRepository)
final accountRepositoryProvider =
    AutoDisposeProvider<AccountRepository>.internal(
      accountRepository,
      name: r'accountRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$accountRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AccountRepositoryRef = AutoDisposeProviderRef<AccountRepository>;
String _$accountListNotifierHash() =>
    r'7223a4e66f491e85aeaf594b9e511ea0a8a0671c';

/// See also [AccountListNotifier].
@ProviderFor(AccountListNotifier)
final accountListNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      AccountListNotifier,
      AccountsResult
    >.internal(
      AccountListNotifier.new,
      name: r'accountListNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$accountListNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AccountListNotifier = AutoDisposeAsyncNotifier<AccountsResult>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
