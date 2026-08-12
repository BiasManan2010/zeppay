import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
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
      if (_name.text.trim().isEmpty || !_upi.text.contains('@')) {
        setState(() => _error = 'Name and a valid UPI ID are required');
        return;
      }
      setState(() {
        _step = 1;
        _error = null;
      });
      return;
    }
    setState(() => _busy = true);
    final bio = ref.read(biometricServiceProvider);
    final available = await bio.isAvailable();
    final ok = !available ||
        await bio.confirm(reason: 'Enroll biometrics — required for every payment');
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
          bankName: _bank.text.trim().isEmpty ? 'Linked bank' : _bank.text.trim(),
          accountLast4: _last4.text.trim(),
        );
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_step == 0 ? 'Link your UPI' : 'Face, every time',
                  style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 8),
              Text(
                _step == 0
                    ? 'This ID is used to build *99# / 123PAY strings. Nothing is typed by hand later.'
                    : 'Biometric confirmation is the trust moment before every payment. Not optional.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              if (_step == 0) ...[
                TextField(controller: _name, decoration: const InputDecoration(labelText: 'YOUR NAME')),
                const SizedBox(height: 12),
                TextField(
                  controller: _upi,
                  decoration: const InputDecoration(labelText: 'UPI ID', hintText: 'you@okaxis'),
                ),
                const SizedBox(height: 12),
                TextField(controller: _bank, decoration: const InputDecoration(labelText: 'BANK NAME')),
                const SizedBox(height: 12),
                TextField(
                  controller: _last4,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(labelText: 'ACCOUNT LAST 4', counterText: ''),
                ),
              ] else
                const Expanded(child: Center(child: FaceGlow())),
              if (_error != null) Text(_error!, style: const TextStyle(color: AppColors.danger)),
              const Spacer(),
              HapticScale(
                onTap: _busy ? null : _next,
                enabled: !_busy,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.hero,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(_step == 0 ? 'CONTINUE' : 'ENABLE BIOMETRICS',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.base)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
