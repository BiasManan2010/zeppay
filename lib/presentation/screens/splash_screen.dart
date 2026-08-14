import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand.dart';
import '../../data/local/app_store.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1400), _go);
  }

  void _go() {
    if (!mounted) return;
    final app = ref.read(appStoreProvider);
    if (app.sessionPhone != null && app.profile?.onboarded == true) {
      context.go('/home');
    } else if (app.sessionPhone != null) {
      context.go('/onboarding');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.85,
            colors: [AppColors.heroDeep, AppColors.base],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/branding/zeppay_logo.png',
                width: 180,
                errorBuilder: (_, __, ___) => const BoltCheck(size: 140),
              ),
              const SizedBox(height: 18),
              Text(
                'ZEP PAY',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.white,
                      letterSpacing: 6,
                    ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(begin: const Offset(0.92, 0.92)),
        ),
      ),
    );
  }
}
