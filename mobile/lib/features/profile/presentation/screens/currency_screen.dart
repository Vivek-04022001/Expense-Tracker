import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '_inner_app_bar.dart';

class _Currency {
  const _Currency(this.code, this.name, this.symbol);
  final String code;
  final String name;
  final String symbol;
}

const _currencies = [
  _Currency('INR', 'Indian Rupee', '₹'),
  _Currency('USD', 'US Dollar', '\$'),
  _Currency('EUR', 'Euro', '€'),
  _Currency('GBP', 'British Pound', '£'),
  _Currency('AED', 'UAE Dirham', 'د.إ'),
  _Currency('SGD', 'Singapore Dollar', 'S\$'),
  _Currency('AUD', 'Australian Dollar', 'A\$'),
  _Currency('CAD', 'Canadian Dollar', 'C\$'),
];

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key, required this.current});
  final String current;

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  late String _query;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _query = '';
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<_Currency> get _filtered => _query.isEmpty
      ? _currencies
      : _currencies.where((c) =>
          c.code.toLowerCase().contains(_query.toLowerCase()) ||
          c.name.toLowerCase().contains(_query.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgBase,
      appBar: const InnerAppBar(title: 'Currency'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(color: context.bgSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.borderSubtle)),
              child: Row(
                children: [
                  SizedBox(width: 12),
                  PhosphorIcon(PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular), size: 18, color: context.textTertiary),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(hintText: 'Search currency…', hintStyle: TextStyle(color: context.textTertiary, fontSize: 14), border: InputBorder.none, isDense: true),
                      style: TextStyle(fontSize: 14, color: context.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              decoration: BoxDecoration(color: context.bgSurface, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
              child: ListView.separated(
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => Divider(height: 1, indent: 16, color: context.borderSubtle),
                itemBuilder: (_, i) {
                  final c = _filtered[i];
                  final isSelected = c.code == widget.current;
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(c.code),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: context.bgBase, borderRadius: BorderRadius.circular(10), border: Border.all(color: context.borderSubtle)),
                            child: Center(child: Text(c.symbol, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isSelected ? AppColors.primary500 : context.textPrimary))),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.code, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary500 : context.textPrimary)),
                                Text(c.name, style: TextStyle(fontSize: 12, color: context.textSecondary)),
                              ],
                            ),
                          ),
                          if (isSelected) PhosphorIcon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 16, color: AppColors.primary500),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
