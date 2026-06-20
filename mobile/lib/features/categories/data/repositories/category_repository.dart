import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/db/tables.dart';
import '../../../../core/sync/outbox_service.dart';
import '../../../../core/sync/sync_engine.dart';
import '../datasources/category_local_datasource.dart';
import '../models/category_model.dart';

/// Offline-first category repository. Local-first writes via Drift + outbox.
class CategoryRepository {
  CategoryRepository(AppDatabase db, this._sync)
      : _db = db,
        _local = CategoryLocalDataSource(db),
        _outbox = OutboxService(db);

  final AppDatabase _db;
  final CategoryLocalDataSource _local;
  final OutboxService _outbox;
  final SyncEngine _sync;
  final _uuid = const Uuid();

  Future<List<CategoryModel>> getCategories() => _local.getCategories();

  Future<CategoryModel> createCategory({
    required String name,
    required CategoryKind kind,
    required String icon,
    required String color,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _db.transaction(() async {
      await _local.upsert(CategoriesCompanion.insert(
        id: id,
        name: name,
        kind: kind.toServer(),
        icon: icon,
        color: color,
        createdAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.pending),
      ));
      await _outbox.enqueue(
        entity: 'category',
        op: 'upsert',
        entityId: id,
        updatedAt: now,
        payload: {
          'name': name,
          'kind': kind.toServer(),
          'icon': icon,
          'color': color,
        },
      );
    });

    _sync.syncQuietly();
    return CategoryModel(id: id, name: name, kind: kind, icon: icon, color: color);
  }

  Future<CategoryModel> updateCategory({
    required String id,
    String? name,
    String? icon,
    String? color,
  }) async {
    final now = DateTime.now();

    await _db.transaction(() async {
      await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
        CategoriesCompanion(
          name: name == null ? const Value.absent() : Value(name),
          icon: icon == null ? const Value.absent() : Value(icon),
          color: color == null ? const Value.absent() : Value(color),
          updatedAt: Value(now),
          syncStatus: const Value(SyncStatus.pending),
        ),
      );
      await _outbox.enqueue(
        entity: 'category',
        op: 'upsert',
        entityId: id,
        updatedAt: now,
        payload: {
          if (name != null) 'name': name,
          if (icon != null) 'icon': icon,
          if (color != null) 'color': color,
        },
      );
    });

    _sync.syncQuietly();
    final all = await _local.getCategories();
    return all.firstWhere((c) => c.id == id);
  }

  Future<void> deleteCategory(String id) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await _local.softDelete(id, now, syncStatus: SyncStatus.pending);
      await _outbox.enqueue(
        entity: 'category',
        op: 'delete',
        entityId: id,
        updatedAt: now,
      );
    });
    _sync.syncQuietly();
  }
}
