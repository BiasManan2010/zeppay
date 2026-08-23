import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/chrome.dart';
import '../../core/platform.dart';
import '../../core/ios_web_redirect.dart';
import '../../data/local/app_store.dart';
import '../../data/local/ux_prefs.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    Future<void>.delayed(const Duration(milliseconds: 2600), _go);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    if (!mounted) return;
    if (isIosWeb) {
      redirectIosToPaySite();
      return;
    }
    final app = ref.read(appStoreProvider);
    if (app.sessionPhone != null && app.profile?.onboarded == true) {
      final seen = await UxPrefs.hasSeenOnboarding();
      if (!mounted) return;
      if (!seen) {
        context.go('/walkthrough');
      } else {
        context.go('/home');
      }
    } else if (app.sessionPhone != null) {
      context.go('/onboarding');
    } else {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      body: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final glow = 0.22 + (_pulse.value * 0.18);
          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.78 + (_pulse.value * 0.12),
                      colors: [
                        Color.lerp(AppColors.heroDeep, AppColors.hero,
                            _pulse.value * 0.35)!,
                        AppColors.base,
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 228,
                      height: 228,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.hero.withValues(alpha: glow),
                            blurRadius: 64,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const BrandMark(size: 228),
                    ).animate().fadeIn(duration: 500.ms).scale(
                          begin: const Offset(0.62, 0.62),
                          end: const Offset(1, 1),
                          curve: Curves.easeOutBack,
                          duration: 900.ms,
                        ),
                    const SizedBox(height: 8),
                    Text(
                      'ZEPPAY',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.white,
                            letterSpacing: 8,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                    ).animate(delay: 420.ms).fadeIn(duration: 600.ms).slideY(
                        begin: 0.35, end: 0, curve: Curves.easeOutCubic),
                    const SizedBox(height: 10),
                    Text(
                      'Pay when the internet dies.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ).animate(delay: 720.ms).fadeIn(duration: 700.ms),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
