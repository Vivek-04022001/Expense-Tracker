import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../models/category_model.dart';

/// Local Drift access for transaction categories.
class CategoryLocalDataSource {
  CategoryLocalDataSource(this._db);

  final AppDatabase _db;

  CategoryModel _toModel(CategoryRow r) => CategoryModel(
        id: r.id,
        name: r.name,
        kind: CategoryKind.fromServer(r.kind),
        icon: r.icon,
        color: r.color,
        key: r.key,
        isSystem: r.isSystem,
        sortOrder: r.sortOrder,
      );

  Future<List<CategoryModel>> getCategories({String? kind}) async {
    final query = _db.select(_db.categories)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    if (kind != null) {
      query.where((t) => t.kind.equals(kind));
    }
    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  Future<void> upsert(CategoriesCompanion row) =>
      _db.into(_db.categories).insertOnConflictUpdate(row);

  Future<void> upsertAll(List<CategoriesCompanion> rows) async {
    await _db.batch((b) => b.insertAllOnConflictUpdate(_db.categories, rows));
  }

  Future<void> softDelete(String id, DateTime updatedAt,
      {required String syncStatus}) async {
    await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        deletedAt: Value(updatedAt),
        updatedAt: Value(updatedAt),
        syncStatus: Value(syncStatus),
      ),
    );
  }
}
