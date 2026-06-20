// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$transferRepositoryHash() =>
    r'28372bf357f5b1da1e0b1afb9451e33f71873eb1';

/// See also [transferRepository].
@ProviderFor(transferRepository)
final transferRepositoryProvider =
    AutoDisposeProvider<TransferRepository>.internal(
      transferRepository,
      name: r'transferRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$transferRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TransferRepositoryRef = AutoDisposeProviderRef<TransferRepository>;
String _$transferListNotifierHash() =>
    r'aea26a1f4401d70760ee9715adbe0733d1cd0739';

/// See also [TransferListNotifier].
@ProviderFor(TransferListNotifier)
final transferListNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      TransferListNotifier,
      List<TransferModel>
    >.internal(
      TransferListNotifier.new,
      name: r'transferListNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$transferListNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TransferListNotifier = AutoDisposeAsyncNotifier<List<TransferModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
