import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chrome.dart';
import '../../../core/widgets/ux.dart';
import '../../../data/local/ux_prefs.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pages = PageController();
  var _index = 0;
  var _spend = 'food';

  @override
  void initState() {
    super.initState();
    UxPrefs.defaultSpend().then((v) {
      if (mounted) setState(() => _spend = v);
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    await UxPrefs.saveSpend(_spend);
    if (_index < 2) {
      _pages.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackdrop(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Column(
          children: [
            GoalBar(
              done: 1 + _index,
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
                  _ikeaSlide(context),
                  _valueSlide(
                    context,
                    Icons.cell_tower_rounded,
                    'Offline is\nthe feature.',
                    '*99# on most SIMs. 123PAY on Jio. You only type the UPI PIN — we already picked the rail.',
                  ),
                  _valueSlide(
                    context,
                    Icons.groups_rounded,
                    'Split like\nyou actually live.',
                    'Trips, houses, 1-on-1s. Settle on the same rails you pay a tea stall with.',
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
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
              label: _index == 2 ? 'CLAIM MY NUMBER' : 'KEEP GOING',
              onTap: _next,
            ),
          ],
        ),
      ),
    );
  }

  Widget _ikeaSlide(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 8),
        const GiftNote(
          icon: Icons.qr_code_2_rounded,
          title: 'Your number. Your name.',
          body:
              'No demo balance. You add a photo and UPI ID — then scan or share your QR.',
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06),
        const SizedBox(height: 18),
        Text(
          'What do you pay for most?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'One tap now. We’ll park that as your default spend chip — you can change it every payment.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        ChoicePills(
          selected: _spend,
          onPick: (id) => setState(() => _spend = id),
          options: const [
            ('food', 'Food'),
            ('travel', 'Travel'),
            ('bills', 'Bills'),
            ('recharge', 'Recharge'),
            ('shopping', 'Shopping'),
            ('other', 'Other'),
          ],
        ),
        const SizedBox(height: 16),
        const LossNote(
          text:
              'Skip this and every pay starts from a blank chip — extra taps you’ll feel later.',
        ),
      ],
    );
  }

  Widget _valueSlide(
    BuildContext context,
    IconData icon,
    String title,
    String body,
  ) {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 140,
          height: 140,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.scanOrb,
          ),
          child: Icon(icon, size: 52, color: AppColors.white),
        ).animate().fadeIn(duration: 360.ms).scale(
              begin: const Offset(0.88, 0.88),
            ),
        const SizedBox(height: 28),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(height: 1.1),
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
