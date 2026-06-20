import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';

part 'category_provider.g.dart';

@riverpod
CategoryRepository categoryRepository(CategoryRepositoryRef ref) =>
    CategoryRepository(
      ref.watch(dioClientProvider),
      ref.watch(appDatabaseProvider),
      ref.watch(syncEngineProvider),
    );

@riverpod
class CategoryListNotifier extends _$CategoryListNotifier {
  @override
  Future<List<CategoryModel>> build() async {
    return ref.watch(categoryRepositoryProvider).getCategories();
  }

  Future<void> create({
    required String name,
    required CategoryKind kind,
    required String icon,
    required String color,
  }) async {
    final created = await ref.read(categoryRepositoryProvider).createCategory(
          name: name,
          kind: kind,
          icon: icon,
          color: color,
        );
    state = AsyncValue.data([...?state.valueOrNull, created]);
  }

  Future<void> edit({
    required String id,
    String? name,
    String? icon,
    String? color,
  }) async {
    final updated = await ref.read(categoryRepositoryProvider).updateCategory(
          id: id,
          name: name,
          icon: icon,
          color: color,
        );
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([
      for (final c in current) c.id == id ? updated : c,
    ]);
  }

  Future<void> delete(String id) async {
    await ref.read(categoryRepositoryProvider).deleteCategory(id);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((c) => c.id != id).toList());
  }
}

/// Categories of a given kind, ready for selectors and list sections.
@riverpod
List<CategoryModel> categoriesByKind(
  CategoriesByKindRef ref,
  CategoryKind kind,
) {
  final all = ref.watch(categoryListNotifierProvider).valueOrNull ?? [];
  return all.where((c) => c.kind == kind).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
}
