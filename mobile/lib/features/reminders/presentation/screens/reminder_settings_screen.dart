import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/screens/_inner_app_bar.dart';
import '../providers/reminder_provider.dart';

class ReminderSettingsScreen extends ConsumerWidget {
  const ReminderSettingsScreen({super.key});

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool value) async {
    final granted =
        await ref.read(reminderProvider.notifier).setEnabled(value);
    if (value && !granted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notifications are turned off. Enable them in system settings '
            'to receive reminders.',
          ),
        ),
      );
    }
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final current = ref.read(reminderProvider).time;
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked != null) {
      await ref.read(reminderProvider.notifier).setTime(picked);
    }
  }

  Future<void> _pickSecondTime(BuildContext context, WidgetRef ref) async {
    final current = ref.read(reminderProvider).secondTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked != null) {
      await ref.read(reminderProvider.notifier).setSecondTime(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(reminderProvider);

    return Scaffold(
      backgroundColor: context.bgBase,
      appBar: const InnerAppBar(title: 'Reminders'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Card(
            children: [
              _ToggleRow(
                icon: PhosphorIcons.bell(PhosphorIconsStyle.fill),
                iconBg: AppColors.warning,
                label: 'Daily reminder',
                subtitle: 'Nudge me to log my expenses and savings',
                value: settings.enabled,
                onChanged: (v) => _toggle(context, ref, v),
              ),
              Divider(height: 1, indent: 64, color: context.borderSubtle),
              _TimeRow(
                label: 'First reminder time',
                enabled: settings.enabled,
                time: settings.time,
                onTap: settings.enabled ? () => _pickTime(context, ref) : null,
              ),
            ],
          ),
          if (settings.enabled) ...[
            const SizedBox(height: 20),
            _Card(
              children: [
                _ToggleRow(
                  icon: PhosphorIcons.bellRinging(PhosphorIconsStyle.fill),
                  iconBg: AppColors.primary500,
                  label: 'Second reminder',
                  subtitle: 'Add another nudge at a different time',
                  value: settings.secondEnabled,
                  onChanged: (v) =>
                      ref.read(reminderProvider.notifier).setSecondEnabled(v),
                ),
                Divider(height: 1, indent: 64, color: context.borderSubtle),
                _TimeRow(
                  label: 'Second reminder time',
                  enabled: settings.secondEnabled,
                  time: settings.secondTime,
                  onTap: settings.secondEnabled
                      ? () => _pickSecondTime(context, ref)
                      : null,
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Choose up to two times a day to be reminded. Turn reminders '
              'off anytime.',
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            ),
          ),
          if (settings.enabled) ...[
            const SizedBox(height: 20),
            _Card(
              children: [
                _ActionRow(
                  icon: PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.fill),
                  iconBg: AppColors.info,
                  label: 'Send a test notification',
                  onTap: () => ref
                      .read(notificationServiceProvider)
                      .showTestNotification(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.bg, this.dimmed = false});
  final PhosphorIconData icon;
  final Color bg;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: dimmed ? bg.withValues(alpha: 0.4) : bg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Center(
        child: PhosphorIcon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final PhosphorIconData icon;
  final Color iconBg;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _IconBox(icon: icon, bg: iconBg),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary500,
          ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.enabled,
    required this.time,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final TimeOfDay time;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? context.textPrimary : context.textTertiary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _IconBox(
              icon: PhosphorIcons.clock(PhosphorIconsStyle.fill),
              bg: AppColors.primary500,
              dimmed: !enabled,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Text(
              time.format(context),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: enabled ? AppColors.primary500 : context.textTertiary,
              ),
            ),
            const SizedBox(width: 4),
            PhosphorIcon(
              PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
              size: 14,
              color: context.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.onTap,
  });

  final PhosphorIconData icon;
  final Color iconBg;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _IconBox(icon: icon, bg: iconBg),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary,
                ),
              ),
            ),
            PhosphorIcon(
              PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
              size: 14,
              color: context.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
