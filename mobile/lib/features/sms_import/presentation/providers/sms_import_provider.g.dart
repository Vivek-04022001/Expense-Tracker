// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_import_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$smsImportServiceHash() => r'1b1208988ef6c24cfabb6f009c608b0865edcf65';

/// See also [smsImportService].
@ProviderFor(smsImportService)
final smsImportServiceProvider = AutoDisposeProvider<SmsImportService>.internal(
  smsImportService,
  name: r'smsImportServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$smsImportServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SmsImportServiceRef = AutoDisposeProviderRef<SmsImportService>;
String _$smsImportControllerHash() =>
    r'37e107d34bdc1005a03fcada1bc43ec7b5366fbe';

/// See also [SmsImportController].
@ProviderFor(SmsImportController)
final smsImportControllerProvider =
    AutoDisposeNotifierProvider<SmsImportController, SmsImportState>.internal(
      SmsImportController.new,
      name: r'smsImportControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$smsImportControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SmsImportController = AutoDisposeNotifier<SmsImportState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
