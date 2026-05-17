import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  void _next() {
    if (_page < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await ref.read(onboardingNotifierProvider.notifier).markSeen();
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: AppColors.lightTextSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: const [
                  _PageContent(index: 0, illustration: _SmsIllustration()),
                  _PageContent(index: 1, illustration: _AutoImportIllustration()),
                  _PageContent(index: 2, illustration: _BudgetIllustration()),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => _Dot(active: i == _page)),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _page < 2 ? 'Next' : 'Get started',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({required this.index, required this.illustration});

  final int index;
  final Widget illustration;

  static const _titles = [
    'Your SMS already\nknows.',
    'Auto-import.\nZero typing.',
    'Know where money\ngoes.',
  ];

  static const _subtitles = [
    'We read your bank and UPI alerts to auto-import every expense. No typing, no tagging.',
    'Transactions appear in seconds, categorized for you. Correct one and we learn forever.',
    'Weekly reality checks, budget nudges, and the one insight that matters most — right now.',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Center(child: illustration),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titles[index],
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _subtitles[index],
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.lightTextSecondary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 22 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.primary500 : const Color(0xFFDDE1EC),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ─── Illustration 1 – SMS auto-import ────────────────────────────────────────

class _SmsIllustration extends StatelessWidget {
  const _SmsIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      width: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 240,
            height: 240,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF0F3FF),
            ),
          ),
          // Left phone – SMS notification
          Positioned(
            left: 12,
            top: 44,
            child: _PhoneCard(
              width: 118,
              height: 148,
              background: const Color(0xFF1C1E2A),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFF4D6A),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _Bar(width: 56, color: Colors.white54, height: 6),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _Bar(width: 88, color: Colors.white38, height: 7),
                  const SizedBox(height: 5),
                  _Bar(width: 66, color: Colors.white24, height: 7),
                  const SizedBox(height: 5),
                  _Bar(width: 78, color: Colors.white38, height: 7),
                  const SizedBox(height: 5),
                  _Bar(width: 52, color: Colors.white24, height: 7),
                  const SizedBox(height: 5),
                  _Bar(width: 70, color: Colors.white38, height: 7),
                ],
              ),
            ),
          ),
          // Animated dots / arrow between cards
          Positioned(
            left: 136,
            top: 116,
            child: Row(
              children: [
                ...List.generate(
                  3,
                  (i) => Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary500.withOpacity(0.6 + i * 0.15),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: AppColors.primary500,
                ),
              ],
            ),
          ),
          // Right phone – parsed expense
          Positioned(
            right: 12,
            top: 58,
            child: _PhoneCard(
              width: 118,
              height: 148,
              background: Colors.white,
              hasShadow: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary500,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'AUTO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Bar(width: 88, color: Colors.black12, height: 7),
                  const SizedBox(height: 5),
                  _Bar(
                    width: 52,
                    color: AppColors.categoryFood.withOpacity(0.45),
                    height: 7,
                  ),
                  const SizedBox(height: 5),
                  _Bar(width: 72, color: Colors.black12, height: 7),
                  const SizedBox(height: 5),
                  _Bar(
                    width: 60,
                    color: AppColors.primary500.withOpacity(0.35),
                    height: 7,
                  ),
                  const SizedBox(height: 5),
                  _Bar(
                    width: 80,
                    color: AppColors.categoryTransport.withOpacity(0.35),
                    height: 7,
                  ),
                ],
              ),
            ),
          ),
          // Small decorative dots
          Positioned(
            top: 22,
            left: 38,
            child: _Bubble(size: 8, color: AppColors.primary100),
          ),
          Positioned(
            bottom: 28,
            right: 32,
            child: _Bubble(size: 10, color: AppColors.primary100),
          ),
          Positioned(
            bottom: 18,
            left: 22,
            child: _Bubble(size: 6, color: AppColors.primary500.withOpacity(0.2)),
          ),
        ],
      ),
    );
  }
}

// ─── Illustration 2 – Auto-import cards around star ──────────────────────────

class _AutoImportIllustration extends StatelessWidget {
  const _AutoImportIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      width: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer soft glow circle
          Container(
            width: 220,
            height: 220,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF2EFFE),
            ),
          ),
          // Inner circle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEAE4FD).withOpacity(0.7),
            ),
          ),
          // Center star icon
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary500,
            ),
            child: Center(
              child: PhosphorIcon(
                PhosphorIcons.star(PhosphorIconsStyle.fill),
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          // Transaction cards scattered around
          Positioned(
            top: 18,
            right: 52,
            child: _TxCard(amount: '₹543', color: AppColors.accent500),
          ),
          Positioned(
            top: 68,
            left: 4,
            child: _TxCard(amount: '₹219', color: AppColors.primary500),
          ),
          Positioned(
            bottom: 22,
            left: 14,
            child: _TxCard(amount: '₹2,303', color: AppColors.categoryFood),
          ),
          Positioned(
            bottom: 28,
            right: 8,
            child: _TxCard(amount: '₹1,045', color: AppColors.warning),
          ),
          Positioned(
            top: 36,
            left: 46,
            child: _TxCard(amount: '₹780', color: AppColors.categoryShopping),
          ),
        ],
      ),
    );
  }
}

// ─── Illustration 3 – Budget donut chart ─────────────────────────────────────

class _BudgetIllustration extends StatelessWidget {
  const _BudgetIllustration();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 200,
          width: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  centerSpaceRadius: 62,
                  sectionsSpace: 0,
                  startDegreeOffset: -90,
                  sections: [
                    PieChartSectionData(
                      value: 70,
                      color: AppColors.primary500,
                      radius: 30,
                      title: '',
                    ),
                    PieChartSectionData(
                      value: 30,
                      color: const Color(0xFFECEDF0),
                      radius: 30,
                      title: '',
                    ),
                  ],
                ),
              ),
              const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '70%',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.lightTextPrimary,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'of ₹60,000',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 22,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6FFF6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'On track',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _Legend(color: AppColors.categoryFood, label: 'Food'),
            SizedBox(width: 18),
            _Legend(color: AppColors.categoryTransport, label: 'Transport'),
            SizedBox(width: 18),
            _Legend(color: AppColors.categoryShopping, label: 'Shopping'),
          ],
        ),
      ],
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _PhoneCard extends StatelessWidget {
  const _PhoneCard({
    required this.width,
    required this.height,
    required this.background,
    required this.child,
    this.hasShadow = false,
  });

  final double width;
  final double height;
  final Color background;
  final Widget child;
  final bool hasShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.09),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.width,
    required this.color,
    this.height = 7,
  });

  final double width;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _TxCard extends StatelessWidget {
  const _TxCard({required this.amount, required this.color});

  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}
