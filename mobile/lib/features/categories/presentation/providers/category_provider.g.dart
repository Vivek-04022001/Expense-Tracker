// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$categoryRepositoryHash() =>
    r'7af5c4b51db4287932c10e962b4d145781b820d9';

/// See also [categoryRepository].
@ProviderFor(categoryRepository)
final categoryRepositoryProvider =
    AutoDisposeProvider<CategoryRepository>.internal(
      categoryRepository,
      name: r'categoryRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$categoryRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CategoryRepositoryRef = AutoDisposeProviderRef<CategoryRepository>;
String _$categoriesByKindHash() => r'ef0518651228ef555d3e5f6d75c8e1ba6982c90c';

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

/// Categories of a given kind, ready for selectors and list sections.
///
/// Copied from [categoriesByKind].
@ProviderFor(categoriesByKind)
const categoriesByKindProvider = CategoriesByKindFamily();

/// Categories of a given kind, ready for selectors and list sections.
///
/// Copied from [categoriesByKind].
class CategoriesByKindFamily extends Family<List<CategoryModel>> {
  /// Categories of a given kind, ready for selectors and list sections.
  ///
  /// Copied from [categoriesByKind].
  const CategoriesByKindFamily();

  /// Categories of a given kind, ready for selectors and list sections.
  ///
  /// Copied from [categoriesByKind].
  CategoriesByKindProvider call(CategoryKind kind) {
    return CategoriesByKindProvider(kind);
  }

  @override
  CategoriesByKindProvider getProviderOverride(
    covariant CategoriesByKindProvider provider,
  ) {
    return call(provider.kind);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'categoriesByKindProvider';
}

/// Categories of a given kind, ready for selectors and list sections.
///
/// Copied from [categoriesByKind].
class CategoriesByKindProvider
    extends AutoDisposeProvider<List<CategoryModel>> {
  /// Categories of a given kind, ready for selectors and list sections.
  ///
  /// Copied from [categoriesByKind].
  CategoriesByKindProvider(CategoryKind kind)
    : this._internal(
        (ref) => categoriesByKind(ref as CategoriesByKindRef, kind),
        from: categoriesByKindProvider,
        name: r'categoriesByKindProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$categoriesByKindHash,
        dependencies: CategoriesByKindFamily._dependencies,
        allTransitiveDependencies:
            CategoriesByKindFamily._allTransitiveDependencies,
        kind: kind,
      );

  CategoriesByKindProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.kind,
  }) : super.internal();

  final CategoryKind kind;

  @override
  Override overrideWith(
    List<CategoryModel> Function(CategoriesByKindRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CategoriesByKindProvider._internal(
        (ref) => create(ref as CategoriesByKindRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        kind: kind,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<List<CategoryModel>> createElement() {
    return _CategoriesByKindProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CategoriesByKindProvider && other.kind == kind;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, kind.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CategoriesByKindRef on AutoDisposeProviderRef<List<CategoryModel>> {
  /// The parameter `kind` of this provider.
  CategoryKind get kind;
}

class _CategoriesByKindProviderElement
    extends AutoDisposeProviderElement<List<CategoryModel>>
    with CategoriesByKindRef {
  _CategoriesByKindProviderElement(super.provider);

  @override
  CategoryKind get kind => (origin as CategoriesByKindProvider).kind;
}

String _$categoryListNotifierHash() =>
    r'f8ad2951d14c5c7c6d4e12ef8b6156873106a384';

/// See also [CategoryListNotifier].
@ProviderFor(CategoryListNotifier)
final categoryListNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      CategoryListNotifier,
      List<CategoryModel>
    >.internal(
      CategoryListNotifier.new,
      name: r'categoryListNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$categoryListNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CategoryListNotifier = AutoDisposeAsyncNotifier<List<CategoryModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
