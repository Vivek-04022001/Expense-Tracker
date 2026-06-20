import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../sms_import/presentation/providers/sms_import_provider.dart';
import '../../../sms_import/presentation/screens/sms_preview_screen.dart';
import '_inner_app_bar.dart';

class SmsImportScreen extends ConsumerStatefulWidget {
  const SmsImportScreen({super.key});

  @override
  ConsumerState<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends ConsumerState<SmsImportScreen> {
  final _textController = TextEditingController();
  bool _parsing = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _onParse() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() => _parsing = true);
    final added = await ref
        .read(smsImportControllerProvider.notifier)
        .parsePasted(text);
    if (added) _textController.clear();
    setState(() => _parsing = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smsImportControllerProvider);

    return Scaffold(
      backgroundColor: context.bgBase,
      appBar: const InnerAppBar(title: 'SMS Import'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Explainer illustration ─────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/illustrations/sms_import_explainer.png',
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ),
          const SizedBox(height: 16),
          // ── Paste SMS card ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.bgSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary500,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: PhosphorIcon(
                          PhosphorIcons.clipboard(PhosphorIconsStyle.fill),
                          size: 17,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Paste a bank SMS',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                          Text(
                            'Copy a transaction SMS from your messaging app and paste it below.',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _textController,
                  maxLines: 5,
                  style: TextStyle(fontSize: 13, color: context.textPrimary),
                  decoration: InputDecoration(
                    hintText:
                        'e.g. Rs.450.00 debited from a/c **4321 on 12-May-26. Info: Swiggy.',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: context.textTertiary,
                    ),
                    filled: true,
                    fillColor: context.bgBase,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: context.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: context.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: AppColors.primary500, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                if (state.parseError != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.warning(PhosphorIconsStyle.fill),
                        size: 14,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          state.parseError!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _parsing ? null : _onParse,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary500,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _parsing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Parse SMS',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // ── Queued transactions card ───────────────────────────────────
          if (state.rows.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  PhosphorIcon(
                    PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                    size: 20,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${state.rows.length} transaction'
                      '${state.rows.length == 1 ? '' : 's'} ready to review',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SmsPreviewScreen(),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Review & Import',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],

          // ── Supported banks ────────────────────────────────────────────
          const SizedBox(height: 24),
          Text(
            'SUPPORTED BANKS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.textTertiary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
            child: Column(
              children: [
                'HDFC Bank',
                'ICICI Bank',
                'SBI',
                'Axis Bank',
                'Kotak',
                'Yes Bank',
                'IndusInd',
              ].map((bank) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          PhosphorIcon(
                            PhosphorIcons.bank(PhosphorIconsStyle.fill),
                            size: 18,
                            color: context.textSecondary,
                          ),
                          const SizedBox(width: 14),
                          Text(
                            bank,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: context.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (bank != 'IndusInd')
                      Divider(
                        height: 1,
                        indent: 46,
                        color: context.borderSubtle,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 150),
        ],
      ),
    );
  }
}
