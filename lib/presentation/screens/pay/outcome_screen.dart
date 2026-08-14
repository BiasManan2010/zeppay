import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/chrome.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/models.dart';
import '../../../data/services/providers.dart';

class OutcomeScreen extends ConsumerWidget {
  const OutcomeScreen({super.key});

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    TxStatus status,
  ) async {
    final id = ref.read(pendingTxIdProvider);
    if (id != null) {
      await ref.read(appStoreProvider.notifier).resolveTransaction(id, status);
    }
    final draft = ref.read(paymentDraftProvider);
    if (status == TxStatus.success && draft?.requestId != null) {
      await ref
          .read(appStoreProvider.notifier)
          .updateRequest(draft!.requestId!, RequestStatus.paid);
    }
    if (status == TxStatus.success &&
        draft?.settleGroupId != null &&
        draft?.settleFromId != null &&
        draft?.settleToId != null) {
      await ref.read(appStoreProvider.notifier).addSettlement(
            Settlement(
              id: AppStore.id(),
              groupId: draft!.settleGroupId!,
              fromId: draft.settleFromId!,
              toId: draft.settleToId!,
              amountPaise: draft.amountPaise,
              createdAt: DateTime.now(),
              method: 'in_app',
            ),
          );
    }
    if (!context.mounted) return;
    if (status == TxStatus.success) {
      context.go('/confirm');
    } else if (status == TxStatus.pending) {
      context.go('/pending');
    } else {
      context.go('/failed');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(paymentDraftProvider);
    return AuthBackdrop(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Did it go through?',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'USSD and 123PAY run in the dialer. Tell us what happened so history stays honest.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${(draft?.amountRupees ?? 0).toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  Text(
                    draft?.payeeName.isNotEmpty == true
                        ? draft!.payeeName
                        : (draft?.vpa ?? ''),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    draft?.vpa ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Spacer(),
            GlowButton(
              label: 'YES, PAID',
              onTap: () => _pick(context, ref, TxStatus.success),
            ),
            const SizedBox(height: 10),
            GlowButton(
              label: 'STILL PENDING',
              onTap: () => _pick(context, ref, TxStatus.pending),
            ),
            const SizedBox(height: 10),
            HapticScale(
              onTap: () => _pick(context, ref, TxStatus.failed),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: Center(
                  child: Text(
                    'FAILED / DROPPED',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: AppColors.danger),
                  ),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.05, curve: Curves.easeOutCubic),
      ),
    );
  }
}
