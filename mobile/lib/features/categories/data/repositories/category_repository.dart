import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final DioClient _dioClient;

  CategoryRepository(this._dioClient);

  Future<List<CategoryModel>> getCategories() async {
    final response = await _dioClient.get(ApiConstants.categories);
    return (response.data['categories'] as List)
        .cast<Map<String, dynamic>>()
        .map(CategoryModel.fromJson)
        .toList();
  }

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
    return CategoryModel.fromJson(
        response.data['category'] as Map<String, dynamic>);
  }

  Future<void> deleteCategory(String id) async {
    await _dioClient.delete(ApiConstants.categoryById(id));
  }
}
