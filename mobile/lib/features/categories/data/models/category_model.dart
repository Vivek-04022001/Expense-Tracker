import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../category_icons.dart';

enum CategoryKind {
  expense,
  income;

  static CategoryKind fromServer(String value) =>
      value == 'income' ? CategoryKind.income : CategoryKind.expense;

  String toServer() => name;
}

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.kind,
    required this.icon,
    required this.color,
    this.key,
    this.isSystem = false,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final CategoryKind kind;

  /// Icon key (e.g. "forkKnife"); resolved via [CategoryIcons].
  final String icon;

  /// Accent color stored as a hex string (e.g. "#FF6B4A").
  final String color;

  /// Stable identifier for seeded built-ins (mirrors the legacy enum value);
  /// null for user-created custom categories.
  final String? key;

  final bool isSystem;
  final int sortOrder;

  PhosphorIconData get phosphorIcon => CategoryIcons.resolve(icon);

  Color get displayColor {
    final hex = color.replaceFirst('#', '');
    if (hex.length == 6) {
      final value = int.tryParse('FF$hex', radix: 16);
      if (value != null) return Color(value);
    }
    return const Color(0xFF8A90A0);
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        kind: CategoryKind.fromServer(json['kind'] as String? ?? 'expense'),
        icon: json['icon'] as String? ?? 'tag',
        color: json['color'] as String? ?? '#8A90A0',
        key: json['key'] as String?,
        isSystem: json['isSystem'] as bool? ?? false,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );
}
