import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/chrome.dart';
import '../../../core/widgets/pay_motion.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/models.dart';
import '../../../data/services/providers.dart';
import '../../../data/services/receipt_share.dart';
import '../../../data/services/sound_cue_service.dart';

class ConfirmScreen extends ConsumerStatefulWidget {
  const ConfirmScreen({super.key});

  @override
  ConsumerState<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends ConsumerState<ConfirmScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 280), () async {
      HapticFeedback.heavyImpact();
      await SoundCueService().success();
    });
  }

  TxRecord? get _tx {
    final id = ref.read(pendingTxIdProvider);
    final txs = ref.read(appStoreProvider).transactions;
    if (id == null) return null;
    return txs.where((t) => t.id == id).firstOrNull;
  }

  void _clear() {
    ref.read(paymentDraftProvider.notifier).state = null;
    ref.read(pendingTxIdProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(paymentDraftProvider);
    final tx = _tx;
    final amount = tx?.amountPaise ?? draft?.amountPaise ?? 0;
    final who = (tx?.payeeName.isNotEmpty == true)
        ? tx!.payeeName
        : (draft?.payeeName.isNotEmpty == true
              ? draft!.payeeName
              : (tx?.vpa ?? draft?.vpa ?? ''));
    final vpa = tx?.vpa ?? draft?.vpa ?? '';
    final refCode = tx?.refCode.isNotEmpty == true ? tx!.refCode : (tx?.id ?? '');
    final when = tx?.createdAt ?? DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: Column(
          children: [
            const ConfettiBurst(),
            const PaymentSuccessBurst(),
            const SizedBox(height: 18),
            Text(
                  'Payment Successful',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                  ),
                )
                .animate()
                .fadeIn(delay: 200.ms)
                .slideY(begin: 0.2, duration: 400.ms),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: amount / 100),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Text(
                '₹${value.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ).animate().fadeIn(delay: 120.ms),
            Text(who, style: Theme.of(context).textTheme.titleMedium),
            Text(vpa, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            if (refCode.isNotEmpty)
              Text(
                'Txn $refCode',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.hero,
                      letterSpacing: 1.1,
                    ),
              ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SurfaceCard(
                child: Column(
                  children: [
                    _row('Paid to', who),
                    _row('UPI ID', vpa),
                    _row('Zep Pay ID', refCode),
                    _row(
                      'On',
                      DateFormat('d MMM y, h:mm a').format(when),
                    ),
                    if ((tx?.note ?? draft?.note ?? '').isNotEmpty)
                      _row('Note', tx?.note ?? draft?.note ?? ''),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 360.ms).slideY(begin: 0.12),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: tx == null
                          ? null
                          : () => ReceiptShare.share(tx),
                      icon: const Icon(Icons.ios_share_rounded),
                      label: const Text('Share'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        startPayment(
                          ref,
                          vpa: vpa,
                          amountPaise: amount,
                          payeeName: who,
                          note: tx?.note ?? draft?.note ?? '',
                          source: 'again',
                        );
                        ref.read(pendingTxIdProvider.notifier).state = null;
                        context.go('/pay/amount');
                      },
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Pay again'),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: GlowButton(
                label: 'DONE',
                onTap: () {
                  _clear();
                  context.go('/home');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(k, style: const TextStyle(color: AppColors.textDim)),
          const Spacer(),
          Flexible(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class FailedScreen extends ConsumerWidget {
  const FailedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(paymentDraftProvider);
    final id = ref.watch(pendingTxIdProvider);
    final tx = ref.watch(appStoreProvider).transactions.where((t) => t.id == id).firstOrNull;
    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const PaymentFailMark(),
              const SizedBox(height: 20),
              Text(
                'Payment Failed',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${(draft?.amountRupees ?? 0).toStringAsFixed(2)} to ${draft?.payeeName.isNotEmpty == true ? draft!.payeeName : (draft?.vpa ?? '')}',
                textAlign: TextAlign.center,
              ),
              if ((tx?.refCode ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Txn ${tx!.refCode}'),
              ],
              const SizedBox(height: 8),
              const Text(
                'Nothing was taken in Zep Pay. Try again when the call or PIN prompt is ready.',
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              GlowButton(
                label: 'TRY AGAIN',
                onTap: () => context.go('/pay/amount'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  ref.read(paymentDraftProvider.notifier).state = null;
                  ref.read(pendingTxIdProvider.notifier).state = null;
                  context.go('/home');
                },
                child: const Text('Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PendingScreen extends ConsumerWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(paymentDraftProvider);
    final id = ref.watch(pendingTxIdProvider);
    final tx = ref
        .watch(appStoreProvider)
        .transactions
        .where((t) => t.id == id)
        .firstOrNull;
    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const PaymentPendingMark(),
              const SizedBox(height: 20),
              Text(
                'Payment Pending',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${(draft?.amountRupees ?? 0).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const Text(
                'Check SMS from your bank, or History in a minute.',
                textAlign: TextAlign.center,
              ),
              if ((tx?.refCode ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Txn ${tx!.refCode}'),
              ],
              const Spacer(),
              GlowButton(
                label: 'SEE HISTORY',
                onTap: () {
                  ref.read(paymentDraftProvider.notifier).state = null;
                  ref.read(pendingTxIdProvider.notifier).state = null;
                  context.go('/history');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
