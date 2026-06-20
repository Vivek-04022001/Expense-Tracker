import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/router/transitions.dart';
import '../../../../core/sync/sync_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../accounts/presentation/screens/accounts_screen.dart';
import '../../../auth/data/models/auth_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../budgets/presentation/providers/budget_provider.dart';
import '../../../budgets/presentation/screens/budgets_screen.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/presentation/screens/categories_screen.dart';
import '../../../reminders/presentation/providers/reminder_provider.dart';
import '../../../reminders/presentation/screens/reminder_settings_screen.dart';
import '../../../transfers/presentation/providers/transfer_provider.dart';
import '../../../transfers/presentation/screens/transfers_screen.dart';
import '../widgets/profile_row.dart';
import '../widgets/profile_user_card.dart';
import 'help_support_screen.dart';
import 'privacy_policy_screen.dart';
import 'theme_screen.dart';

String _lastSyncedLabel(DateTime? at) {
  if (at == null) return 'Tap to sync';
  final diff = DateTime.now().difference(at);
  if (diff.inMinutes < 1) return 'Synced just now';
  if (diff.inMinutes < 60) return 'Synced ${diff.inMinutes}m ago';
  if (diff.inHours < 24) return 'Synced ${diff.inHours}h ago';
  return 'Synced ${diff.inDays}d ago';
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // Push on the root navigator so these detail screens sit above the shell's
  // bottom navigation bar instead of being overlapped by it.
  void _push(BuildContext context, Widget screen) =>
      Navigator.of(context, rootNavigator: true).push(slideFadeRoute(screen));

  void _openEdit(BuildContext context, WidgetRef ref, UserModel user) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: context.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProfileSheet(
        name: user.name,
        phone: user.phone,
        onSave: (name) =>
            ref.read(authNotifierProvider.notifier).updateProfile(name: name),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sign out?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          'You will need to sign in again to access your data.',
          style: TextStyle(color: context.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: TextStyle(color: context.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Sign out',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (shouldLogout == true) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider).valueOrNull;
    final user = authState is AuthAuthenticated ? authState.user : null;

    final budgetCount = ref.watch(budgetListNotifierProvider).valueOrNull?.length;
    final categoryCount =
        ref.watch(categoryListNotifierProvider).valueOrNull?.length;
    final transferCount =
        ref.watch(transferListNotifierProvider).valueOrNull?.length;

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
            SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/illustrations/profile_header_banner.png',
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 12),
            ProfileUserCard(
              name: user?.name ?? '—',
              phone: user?.phone ?? '',
              onEdit:
                  user == null ? null : () => _openEdit(context, ref, user),
            ),
            SizedBox(height: 24),
            ProfileSection(
              title: 'Finance',
              rows: [
                ProfileRow(
                  icon: PhosphorIcons.cardholder(PhosphorIconsStyle.fill),
                  iconBg: AppColors.info,
                  label: 'Accounts',
                  onTap: () => _push(context, const AccountsScreen()),
                ),
                ProfileRow(
                  icon: PhosphorIcons.wallet(PhosphorIconsStyle.fill),
                  iconBg: AppColors.primary500,
                  label: 'Budgets',
                  trailing: budgetCount == null ? null : '$budgetCount active',
                  onTap: () => _push(context, const BudgetsScreen()),
                ),
                ProfileRow(
                  icon: PhosphorIcons.tag(PhosphorIconsStyle.fill),
                  iconBg: AppColors.categoryShopping,
                  label: 'Categories',
                  trailing: categoryCount == null ? null : '$categoryCount',
                  onTap: () => _push(context, const CategoriesScreen()),
                ),
                ProfileRow(
                  icon: PhosphorIcons.arrowsLeftRight(PhosphorIconsStyle.fill),
                  iconBg: AppColors.info,
                  label: 'Transfers',
                  trailing: transferCount == null ? null : '$transferCount',
                  onTap: () => _push(context, const TransfersScreen()),
                ),
              ],
            ),
            SizedBox(height: 24),
            ProfileSection(
              title: 'Preferences',
              rows: [
                ProfileRow(
                  icon: PhosphorIcons.bell(PhosphorIconsStyle.fill),
                  iconBg: AppColors.warning,
                  label: 'Reminders',
                  trailing: () {
                    final r = ref.watch(reminderProvider);
                    return r.enabled ? r.time.format(context) : 'Off';
                  }(),
                  onTap: () => _push(context, const ReminderSettingsScreen()),
                ),
                ProfileRow(
                  icon: PhosphorIcons.moon(PhosphorIconsStyle.fill),
                  iconBg: const Color(0xFF3D3D4E),
                  label: 'Theme',
                  trailing: themeModeToLabel(ref.watch(themeModeProvider)),
                  onTap: () async {
                    final current = themeModeToLabel(
                      ref.read(themeModeProvider),
                    );
                    final result = await Navigator.of(context).push<String>(
                      slideFadeRoute<String>(ThemeScreen(current: current)),
                    );
                    if (result != null) {
                      ref
                          .read(themeModeProvider.notifier)
                          .setMode(labelToThemeMode(result));
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 24),
            ProfileSection(
              title: 'Data & sync',
              rows: [
                ProfileRow(
                  icon: PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.bold),
                  iconBg: AppColors.info,
                  label: 'Sync now',
                  trailing: () {
                    final s = ref.watch(syncControllerProvider);
                    final pending =
                        ref.watch(pendingCountProvider).valueOrNull ?? 0;
                    if (s.syncing) return 'Syncing…';
                    if (pending > 0) return '$pending pending';
                    return _lastSyncedLabel(s.lastSyncedAt);
                  }(),
                  onTap: () =>
                      ref.read(syncControllerProvider.notifier).syncNow(),
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
                  onTap: () => _push(context, const HelpSupportScreen()),
                ),
                ProfileRow(
                  icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
                  iconBg: const Color(0xFF4A4A5A),
                  label: 'Privacy policy',
                  onTap: () => _push(context, const PrivacyPolicyScreen()),
                ),
              ],
            ),
            SizedBox(height: 24),
            ProfileSection(
              title: 'Account',
              rows: [
                ProfileRow(
                  icon: PhosphorIcons.signOut(PhosphorIconsStyle.fill),
                  iconBg: AppColors.danger,
                  label: 'Sign out',
                  isDestructive: true,
                  onTap: () => _confirmSignOut(context, ref),
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
  final void Function(String name) onSave;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
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
          // Phone is the login identifier and cannot be changed here.
          _ReadOnlyField(label: 'Phone number', value: widget.phone),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(_nameCtrl.text.trim());
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
          style: TextStyle(fontSize: 15, color: context.textPrimary),
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

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});
  final String label;
  final String value;

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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: context.bgBase,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderSubtle),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(fontSize: 15, color: context.textTertiary),
                ),
              ),
              PhosphorIcon(
                PhosphorIcons.lock(PhosphorIconsStyle.regular),
                size: 16,
                color: context.textTertiary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
