import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../accounts/presentation/screens/accounts_screen.dart';
import '../widgets/profile_row.dart';
import '../widgets/profile_user_card.dart';
import 'budgets_screen.dart';
import 'categories_screen.dart';
import 'currency_screen.dart';
import 'export_csv_screen.dart';
import 'help_support_screen.dart';
import 'notifications_screen.dart';
import 'privacy_policy_screen.dart';
import 'recurring_expenses_screen.dart';
import 'sms_import_screen.dart';
import 'theme_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _name = 'Vivek Sharma';
  String _phone = '+91 98765 43210';
  String _currency = 'INR';

  void _openEdit() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: context.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProfileSheet(
        name: _name,
        phone: _phone,
        onSave: (name, phone) => setState(() {
          _name = name;
          _phone = phone;
        }),
      ),
    );
  }

  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear all data?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          'This will permanently delete all your expenses, budgets, and settings. This cannot be undone.',
          style: TextStyle(color: context.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Clear',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _push(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgBase,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            Text(
              'Profile',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            ProfileUserCard(name: _name, phone: _phone, onEdit: _openEdit),
            SizedBox(height: 24),
            ProfileSection(
              title: 'Finance',
              rows: [
                ProfileRow(
                  icon: PhosphorIcons.cardholder(PhosphorIconsStyle.fill),
                  iconBg: AppColors.info,
                  label: 'Accounts',
                  onTap: () => _push(const AccountsScreen()),
                ),
                ProfileRow(
                  icon: PhosphorIcons.wallet(PhosphorIconsStyle.fill),
                  iconBg: AppColors.primary500,
                  label: 'Budgets',
                  trailing: '5 active',
                  onTap: () => _push(const BudgetsScreen()),
                ),
                ProfileRow(
                  icon: PhosphorIcons.tag(PhosphorIconsStyle.fill),
                  iconBg: AppColors.categoryShopping,
                  label: 'Categories',
                  trailing: '8',
                  onTap: () => _push(const CategoriesScreen()),
                ),
                ProfileRow(
                  icon: PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.fill),
                  iconBg: AppColors.warning,
                  label: 'Recurring expenses',
                  trailing: '3',
                  onTap: () => _push(const RecurringExpensesScreen()),
                ),
              ],
            ),
            SizedBox(height: 24),
            ProfileSection(
              title: 'Data',
              rows: [
                ProfileRow(
                  icon: PhosphorIcons.chatText(PhosphorIconsStyle.fill),
                  iconBg: AppColors.success,
                  label: 'SMS auto-import',
                  trailing: 'On · 98%',
                  onTap: () => _push(const SmsImportScreen()),
                ),
                ProfileRow(
                  icon: PhosphorIcons.downloadSimple(PhosphorIconsStyle.fill),
                  iconBg: AppColors.info,
                  label: 'Export CSV',
                  onTap: () => _push(const ExportCsvScreen()),
                ),
                ProfileRow(
                  icon: PhosphorIcons.trash(PhosphorIconsStyle.fill),
                  iconBg: AppColors.danger,
                  label: 'Clear all data',
                  isDestructive: true,
                  onTap: _confirmClearData,
                ),
              ],
            ),
            SizedBox(height: 24),
            ProfileSection(
              title: 'Preferences',
              rows: [
                ProfileRow(
                  icon: PhosphorIcons.moon(PhosphorIconsStyle.fill),
                  iconBg: const Color(0xFF3D3D4E),
                  label: 'Theme',
                  trailing: themeModeToLabel(ref.watch(themeModeProvider)),
                  onTap: () async {
                    final current = themeModeToLabel(ref.read(themeModeProvider));
                    final result = await Navigator.of(context).push<String>(
                      MaterialPageRoute(
                        builder: (_) => ThemeScreen(current: current),
                      ),
                    );
                    if (result != null) {
                      ref.read(themeModeProvider.notifier).setMode(
                        labelToThemeMode(result),
                      );
                    }
                  },
                ),
                ProfileRow(
                  icon: PhosphorIcons.globe(PhosphorIconsStyle.fill),
                  iconBg: const Color(0xFF2E7D6B),
                  label: 'Currency',
                  trailing: _currency,
                  onTap: () async {
                    final result = await Navigator.of(context).push<String>(
                      MaterialPageRoute(
                        builder: (_) => CurrencyScreen(current: _currency),
                      ),
                    );
                    if (result != null) setState(() => _currency = result);
                  },
                ),
                ProfileRow(
                  icon: PhosphorIcons.bell(PhosphorIconsStyle.fill),
                  iconBg: AppColors.warning,
                  label: 'Notifications',
                  trailing: 'Budget alerts',
                  onTap: () => _push(const NotificationsScreen()),
                ),
              ],
            ),
            SizedBox(height: 24),
            ProfileSection(
              title: 'About',
              rows: [
                ProfileRow(
                  icon: PhosphorIcons.question(PhosphorIconsStyle.fill),
                  iconBg: const Color(0xFF4A4A5A),
                  label: 'Help & support',
                  onTap: () => _push(const HelpSupportScreen()),
                ),
                ProfileRow(
                  icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
                  iconBg: const Color(0xFF4A4A5A),
                  label: 'Privacy policy',
                  onTap: () => _push(const PrivacyPolicyScreen()),
                ),
              ],
            ),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// ── Edit profile sheet ────────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.name,
    required this.phone,
    required this.onSave,
  });
  final String name;
  final String phone;
  final void Function(String, String) onSave;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.name);
    _phoneCtrl = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          SizedBox(height: 20),
          _LabeledField(
            label: 'Full name',
            ctrl: _nameCtrl,
            type: TextInputType.name,
          ),
          SizedBox(height: 14),
          _LabeledField(
            label: 'Phone number',
            ctrl: _phoneCtrl,
            type: TextInputType.phone,
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(_nameCtrl.text.trim(), _phoneCtrl.text.trim());
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Save',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.ctrl,
    required this.type,
  });
  final String label;
  final TextEditingController ctrl;
  final TextInputType type;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: context.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: type,
          style: TextStyle(
            fontSize: 15,
            color: context.textPrimary,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.bgBase,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary500),
            ),
          ),
        ),
      ],
    );
  }
}
