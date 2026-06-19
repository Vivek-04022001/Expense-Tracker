import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';

enum AccountType {
  card,
  cash,
  wallet,
  bank,
  savings,
  investment,
  other;

  static AccountType fromServer(String value) => switch (value) {
        'card' => card,
        'cash' => cash,
        'wallet' => wallet,
        'bank' => bank,
        'savings' => savings,
        'investment' => investment,
        _ => other,
      };

  String toServer() => switch (this) {
        AccountType.card => 'card',
        AccountType.cash => 'cash',
        AccountType.wallet => 'wallet',
        AccountType.bank => 'bank',
        AccountType.savings => 'savings',
        AccountType.investment => 'investment',
        AccountType.other => 'other',
      };

  String get displayLabel => switch (this) {
        AccountType.card => 'Card',
        AccountType.cash => 'Cash',
        AccountType.wallet => 'Wallet',
        AccountType.bank => 'Bank',
        AccountType.savings => 'Savings',
        AccountType.investment => 'Investment',
        AccountType.other => 'Other',
      };

  PhosphorIconData get icon => switch (this) {
        AccountType.card => PhosphorIcons.creditCard(PhosphorIconsStyle.fill),
        AccountType.cash => PhosphorIcons.money(PhosphorIconsStyle.fill),
        AccountType.wallet => PhosphorIcons.wallet(PhosphorIconsStyle.fill),
        AccountType.bank => PhosphorIcons.bank(PhosphorIconsStyle.fill),
        AccountType.savings => PhosphorIcons.piggyBank(PhosphorIconsStyle.fill),
        AccountType.investment =>
          PhosphorIcons.chartLineUp(PhosphorIconsStyle.fill),
        AccountType.other => PhosphorIcons.wallet(PhosphorIconsStyle.fill),
      };

  /// Default accent color used when the account has no custom color.
  Color get defaultColor => switch (this) {
        AccountType.card => AppColors.categoryTransport,
        AccountType.cash => AppColors.categoryEducation,
        AccountType.wallet => AppColors.categoryBills,
        AccountType.bank => AppColors.info,
        AccountType.savings => AppColors.categoryShopping,
        AccountType.investment => AppColors.success,
        AccountType.other => AppColors.categoryOther,
      };
}

class AccountModel {
  const AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.color,
  });

  final String id;
  final String name;
  final AccountType type;
  final double balance;

  /// Optional custom color stored as a 6-digit hex string (no leading '#').
  final String? color;

  /// Resolved color — custom if set, otherwise the type's default.
  Color get displayColor {
    final raw = color;
    if (raw != null && raw.length >= 6) {
      final hex = raw.replaceFirst('#', '');
      final value = int.tryParse('FF$hex', radix: 16);
      if (value != null) return Color(value);
    }
    return type.defaultColor;
  }

  factory AccountModel.fromJson(Map<String, dynamic> json) => AccountModel(
        id: json['id'] as String,
        name: json['name'] as String,
        type: AccountType.fromServer(json['type'] as String? ?? 'other'),
        balance: double.parse(json['balance'].toString()),
        color: json['color'] as String?,
      );
}
