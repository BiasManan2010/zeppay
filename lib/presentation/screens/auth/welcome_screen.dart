import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chrome.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pages = PageController();
  var _index = 0;

  static const _slides = [
    (
      icon: Icons.qr_code_2_rounded,
      title: 'Tap. Pay.\nAnytime.',
      body:
          'Scan any UPI QR and confirm with your face. One motion — even when data is gone.',
    ),
    (
      icon: Icons.cell_tower_rounded,
      title: 'Offline is\nthe feature.',
      body:
          'Zeppay picks *99# or 123PAY for your carrier. You only type your UPI PIN.',
    ),
    (
      icon: Icons.groups_rounded,
      title: 'Split like\nyou actually live.',
      body:
          'Trips, houses, 1-on-1s. Settle up on the same rails you pay merchants with.',
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _slides.length - 1) {
      _pages.nextPage(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic);
    } else {
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
              child: PageView.builder(
                controller: _pages,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return Column(
                    children: [
                      const Spacer(),
                      Container(
                        width: 168,
                        height: 168,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.hero.withValues(alpha: 0.4),
                              blurRadius: 40,
                            ),
                          ],
                        ),
                        child: i == 0
                            ? const BrandMark(size: 168)
                            : Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.scanOrb,
                                ),
                                child: Icon(slide.icon,
                                    size: 56, color: AppColors.white),
                              ),
                      )
                          .animate(key: ValueKey(i))
                          .fadeIn(duration: 400.ms)
                          .scale(begin: const Offset(0.86, 0.86)),
                      const SizedBox(height: 36),
                      Text(
                        slide.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(height: 1.1),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        slide.body,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(height: 1.45, fontSize: 15),
                      ),
                      const Spacer(),
                    ],
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
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
            const SizedBox(height: 22),
            GlowButton(
              label: _index == _slides.length - 1 ? 'GET STARTED' : 'NEXT',
              onTap: _next,
            ),
          ],
        ),
      ),
    );
  }
}
