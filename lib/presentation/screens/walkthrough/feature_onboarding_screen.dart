import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/branding_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/local/ux_prefs.dart';
import '../../../l10n/app_localizations.dart';

class FeatureOnboardingScreen extends ConsumerStatefulWidget {
  const FeatureOnboardingScreen({super.key, this.replay = false});

  /// When true, skip does not set the seen flag (Settings replay).
  final bool replay;

  @override
  ConsumerState<FeatureOnboardingScreen> createState() =>
      _FeatureOnboardingScreenState();
}

class _FeatureOnboardingScreenState extends ConsumerState<FeatureOnboardingScreen> {
  final _page = PageController();
  var _index = 0;

  static const _slideCount = 4;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (!widget.replay) {
      await UxPrefs.setHasSeenOnboarding(true);
    }
    if (!mounted) return;
    context.go('/home');
  }

  void _next() {
    if (_index >= _slideCount - 1) {
      _finish();
      return;
    }
    _page.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final slides = [
      _SlideData(
        imageAsset: 'assets/branding/zeppay_transparent_bg.png',
        icon: Icons.bolt_rounded,
        title: l10n.walkthroughWelcomeTitle,
        body: l10n.walkthroughWelcomeBody,
      ),
      _SlideData(
        imageAsset: 'assets/branding/zeppay_mark.png',
        icon: Icons.nfc_rounded,
        title: l10n.walkthroughNfcTitle,
        body: l10n.walkthroughNfcBody,
      ),
      _SlideData(
        icon: Icons.cell_tower_rounded,
        title: l10n.walkthroughOfflineTitle,
        body: l10n.walkthroughOfflineBody,
      ),
      _SlideData(
        imageAsset: BrandingAssets.zepCoin,
        icon: Icons.storefront_outlined,
        title: l10n.walkthroughShopTitle,
        body: l10n.walkthroughShopBody,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(l10n.walkthroughSkip),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _page,
                itemCount: _slideCount,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final s = slides[i];
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: Padding(
                      key: ValueKey(i),
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (s.imageAsset != null)
                            Image.asset(
                              s.imageAsset!,
                              height: 120,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                s.icon,
                                size: 88,
                                color: AppColors.hero,
                              ),
                            )
                          else
                            Icon(s.icon, size: 88, color: AppColors.hero),
                          const SizedBox(height: 32),
                          Text(
                            s.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            s.body,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slideCount,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _index == i ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _index == i
                        ? AppColors.hero
                        : AppColors.hero.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(
                    _index >= _slideCount - 1
                        ? l10n.walkthroughGetStarted
                        : l10n.walkthroughNext,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.icon,
    required this.title,
    required this.body,
    this.imageAsset,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? imageAsset;
}
