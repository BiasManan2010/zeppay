import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chrome.dart';
import '../../../core/widgets/illustrations.dart';
import '../../../core/widgets/ux.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pages = PageController();
  var _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_index < 1) {
      _pages.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackdrop(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Column(
          children: [
            const GoalBar(
              done: 1,
              total: 4,
              label: 'Opened Zep Pay · already moving',
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'Skip',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _valueSlide(
                    context,
                    ZepArt.scan,
                    'Scan. Pay.\nOn this phone.',
                    'Point the camera at any UPI QR — FamPay, GPay, PhonePe, Paytm. Then amount, then your UPI app.',
                  ),
                  _valueSlide(
                    context,
                    ZepArt.split,
                    'Split like\nyou actually live.',
                    'Trips, houses, 1-on-1s. Settle on the same rails you pay a tea stall with.',
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 2; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? AppColors.hero
                          : AppColors.surfaceBorder,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            GlowButton(
              label: _index == 1 ? 'CLAIM MY NUMBER' : 'KEEP GOING',
              onTap: _next,
            ),
          ],
        ),
      ),
    );
  }

  Widget _valueSlide(
    BuildContext context,
    ZepArt art,
    String title,
    String body,
  ) {
    return Column(
      children: [
        const Spacer(),
        ZepIllustration(art, size: 196)
            .animate()
            .fadeIn(duration: 360.ms)
            .scale(begin: const Offset(0.88, 0.88)),
        const SizedBox(height: 28),
        Text(
          title,
          textAlign: TextAlign.center,
          style:
              Theme.of(context).textTheme.displayMedium?.copyWith(height: 1.1),
        ),
        const SizedBox(height: 12),
        Text(
          body,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        const Spacer(),
      ],
    );
  }
}
