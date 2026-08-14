import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/chrome.dart';
import '../../../data/services/providers.dart';
import '../../../data/services/sound_cue_service.dart';

class ConfirmScreen extends ConsumerStatefulWidget {
  const ConfirmScreen({super.key});

  @override
  ConsumerState<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends ConsumerState<ConfirmScreen> {
  var _done = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 700), _log);
  }

  Future<void> _log() async {
    if (ref.read(paymentDraftProvider) != null) {
      await SoundCueService().success();
    }
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(paymentDraftProvider);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGlow),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              BoltCheck(size: 140, complete: _done),
              const SizedBox(height: 12),
              Lottie.asset(
                'assets/lottie/coin_burst.json',
                width: 220,
                height: 140,
                errorBuilder: (_, __, ___) => const SizedBox(height: 140),
              ),
              Text('PAID', style: Theme.of(context).textTheme.labelLarge),
              Text(
                '₹${(draft?.amountRupees ?? 0).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              Text(
                draft?.payeeName.isNotEmpty == true
                    ? draft!.payeeName
                    : (draft?.vpa ?? ''),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: GlowButton(
                  label: 'DONE',
                  onTap: () {
                    ref.read(paymentDraftProvider.notifier).state = null;
                    ref.read(pendingTxIdProvider.notifier).state = null;
                    context.go('/home');
                  },
                ),
              ),
            ],
          ).animate().fadeIn(),
        ),
      ),
    );
  }
}
