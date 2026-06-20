import '../../../../core/constants/api_constants.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/sync/sync_engine.dart';
import '../datasources/category_local_datasource.dart';
import '../models/category_model.dart';

/// Offline-first category repository. Reads from Drift; writes hit the network
/// then trigger a delta sync.
class CategoryRepository {
  CategoryRepository(this._dioClient, AppDatabase db, this._sync)
      : _local = CategoryLocalDataSource(db);

  final DioClient _dioClient;
  final CategoryLocalDataSource _local;
  final SyncEngine _sync;

  Future<List<CategoryModel>> getCategories() => _local.getCategories();

  Future<CategoryModel> createCategory({
    required String name,
    required CategoryKind kind,
    required String icon,
    required String color,
  }) async {
    final response = await _dioClient.post(
      ApiConstants.categories,
      data: {
        'name': name,
        'kind': kind.toServer(),
        'icon': icon,
        'color': color,
      },
    );
    await _sync.pullQuietly();
    return CategoryModel.fromJson(
        response.data['category'] as Map<String, dynamic>);
  }

  Future<CategoryModel> updateCategory({
    required String id,
    String? name,
    String? icon,
    String? color,
  }) async {
    final response = await _dioClient.patch(
      ApiConstants.categoryById(id),
      data: {
        if (name != null) 'name': name,
        if (icon != null) 'icon': icon,
        if (color != null) 'color': color,
      },
    );
    await _sync.pullQuietly();
    return CategoryModel.fromJson(
        response.data['category'] as Map<String, dynamic>);
  }

  Future<void> deleteCategory(String id) async {
    await _dioClient.delete(ApiConstants.categoryById(id));
    await _sync.pullQuietly();
  }
}
