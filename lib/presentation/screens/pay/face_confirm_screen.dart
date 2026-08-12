import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../data/services/providers.dart';

class FaceConfirmScreen extends ConsumerStatefulWidget {
  const FaceConfirmScreen({super.key});

  @override
  ConsumerState<FaceConfirmScreen> createState() => _FaceConfirmScreenState();
}

class _FaceConfirmScreenState extends ConsumerState<FaceConfirmScreen> {
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 700), _confirm);
  }

  Future<void> _confirm() async {
    final draft = ref.read(paymentDraftProvider);
    if (draft == null) {
      if (mounted) context.go('/home');
      return;
    }
    setState(() => _busy = true);
    final ok = await ref.read(biometricServiceProvider).confirm(
          reason: 'Pay ₹${draft.amountRupees.toStringAsFixed(2)} to ${draft.payeeName.isEmpty ? draft.vpa : draft.payeeName}',
        );
    if (!ok) {
      setState(() {
        _busy = false;
        _error = 'Biometric confirmation is required to pay.';
      });
      return;
    }
    if (mounted) context.go('/connecting');
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(paymentDraftProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text('CONFIRM', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 12),
              Text(
                '₹${(draft?.amountRupees ?? 0).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              Text(draft?.payeeName.isNotEmpty == true ? draft!.payeeName : (draft?.vpa ?? ''),
                  style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              const FaceGlow(),
              const SizedBox(height: 16),
              Text(
                _busy ? 'Look at the camera' : 'Tap to try again',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
                const SizedBox(height: 12),
                HapticScale(
                  onTap: _confirm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.hero,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('RETRY'),
                  ),
                ),
              ],
              const Spacer(),
            ],
          ).animate().fadeIn(duration: 500.ms),
        ),
      ),
    );
  }
}
