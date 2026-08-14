import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/chrome.dart';
import '../../../data/local/app_store.dart';
import '../../../data/services/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _name = TextEditingController();
  final _upi = TextEditingController();
  final _bank = TextEditingController();
  final _last4 = TextEditingController();
  var _step = 0;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _upi.dispose();
    _bank.dispose();
    _last4.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_step == 0) {
      if (_name.text.trim().isEmpty) {
        setState(() => _error = 'What should we call you?');
        return;
      }
      setState(() {
        _step = 1;
        _error = null;
      });
      return;
    }
    if (_step == 1) {
      if (!_upi.text.contains('@')) {
        setState(() => _error = 'A valid UPI ID is required');
        return;
      }
      setState(() {
        _step = 2;
        _error = null;
      });
      return;
    }
    setState(() => _busy = true);
    final bio = ref.read(biometricServiceProvider);
    final available = await bio.isAvailable();
    final ok = !available ||
        await bio.confirm(
            reason: 'Enroll biometrics — required for every payment');
    if (!ok) {
      setState(() {
        _busy = false;
        _error = 'Biometric enrollment is required. It cannot be skipped.';
      });
      return;
    }
    await ref.read(appStoreProvider.notifier).completeOnboarding(
          name: _name.text.trim(),
          upiId: _upi.text.trim().toLowerCase(),
          bankName:
              _bank.text.trim().isEmpty ? 'Linked bank' : _bank.text.trim(),
          accountLast4: _last4.text.trim(),
        );
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['You first.', 'Link your UPI.', 'Face, every time.'];
    final bodies = [
      'This is how friends see you in splits and requests.',
      'Used to build *99# / 123PAY strings. You never type it by hand later.',
      'Biometrics gate every payment. Not optional — that’s the trust moment.',
    ];
    return AuthBackdrop(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepPills(count: 3, index: _step),
            const SizedBox(height: 28),
            Text(titles[_step],
                style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 8),
            Text(bodies[_step],
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.4)),
            const SizedBox(height: 28),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: _step == 0
                    ? GlassPanel(
                        key: const ValueKey('you'),
                        child: TextField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'YOUR NAME',
                            hintText: 'Manan',
                          ),
                        ),
                      )
                    : _step == 1
                        ? GlassPanel(
                            key: const ValueKey('upi'),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _upi,
                                  decoration: const InputDecoration(
                                    labelText: 'UPI ID',
                                    hintText: 'you@okaxis',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _bank,
                                  decoration: const InputDecoration(
                                      labelText: 'BANK NAME'),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _last4,
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  decoration: const InputDecoration(
                                    labelText: 'ACCOUNT LAST 4',
                                    counterText: '',
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const Center(
                            key: ValueKey('face'),
                            child: FaceGlow(),
                          ),
              ),
            ),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
              const SizedBox(height: 10),
            ],
            GlowButton(
              label: _step == 0
                  ? 'CONTINUE'
                  : _step == 1
                      ? 'LOCK IT IN'
                      : 'ENABLE BIOMETRICS',
              onTap: _busy ? null : _next,
              busy: _busy,
            ),
          ],
        ).animate().fadeIn(duration: 350.ms),
      ),
    );
  }
}
