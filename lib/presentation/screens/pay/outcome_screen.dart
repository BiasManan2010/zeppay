import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/chrome.dart';
import '../../../data/models/models.dart';
import '../../../data/services/payment_session.dart';
import '../../../data/services/payment_tracker.dart';
import '../../../data/services/payment_verification.dart';
import '../../../data/services/providers.dart';
import '../../../presentation/widgets/payment_track_card.dart';

class OutcomeScreen extends ConsumerStatefulWidget {
  const OutcomeScreen({super.key});

  @override
  ConsumerState<OutcomeScreen> createState() => _OutcomeScreenState();
}

class _OutcomeScreenState extends ConsumerState<OutcomeScreen> {
  UssdUserOutcome? _picked;
  var _amountMatches = false;
  final _smsRef = TextEditingController();
  var _showSuccessGate = false;

  @override
  void dispose() {
    _smsRef.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final outcome = _picked;
    if (outcome == null) return;

    if (outcome == UssdUserOutcome.success) {
      if (!_amountMatches) {
        setState(() => _showSuccessGate = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Confirm the debited amount before marking success.'),
          ),
        );
        return;
      }
      final track = ref.read(paymentSessionProvider).value?.track;
      final guard = track == null
          ? null
          : successGuardMessage(outcome: outcome, track: track);
      if (guard != null && !_showSuccessGate) {
        setState(() => _showSuccessGate = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(guard)),
        );
        return;
      }
    }

    await ref.read(paymentSessionProvider.notifier).recordUserVerification(
          outcome: outcome,
          smsRef: _smsRef.text,
          amountConfirmed: _amountMatches,
        );

    final status = statusFromUserOutcome(outcome);
    final id = ref.read(pendingTxIdProvider);
    if (id != null) {
      await applyPaymentResult(ref, status);
    } else {
      await ref.read(paymentSessionProvider.notifier).clear();
    }
    if (!mounted) return;
    if (status == TxStatus.success) {
      context.go('/confirm');
    } else if (status == TxStatus.pending) {
      context.go('/pending');
    } else {
      context.go('/failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(paymentDraftProvider);
    final track = ref.watch(paymentSessionProvider).value?.track;
    final steps = track == null ? const <PaymentTrackStep>[] : trackSteps(track);
    final amount = draft?.amountRupees ?? 0;
    final guard = _picked == UssdUserOutcome.success && track != null
        ? successGuardMessage(outcome: _picked!, track: track)
        : null;

    return AuthBackdrop(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What did *99# show?',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isWebApp
                  ? 'Zep Pay cannot read your bank. Pick exactly what Phone / USSD displayed — that becomes the record.'
                  : 'Pick what the dialer showed. This is your payment verdict.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (steps.isNotEmpty) ...[
              const SizedBox(height: 12),
              PaymentTrackCard(
                steps: steps,
                title: 'Session log (facts only)',
              ),
            ],
            if (track != null) ...[
              const SizedBox(height: 8),
              Text(
                sessionContextNote(track),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textDim,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${amount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  Text(
                    draft?.payeeName.isNotEmpty == true
                        ? draft!.payeeName
                        : (draft?.vpa ?? ''),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(draft?.vpa ?? '',
                      style: Theme.of(context).textTheme.bodyMedium),
                  if (track?.refCode.isNotEmpty == true)
                    Text(
                      'Ref ${track!.refCode}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  for (final outcome in UssdUserOutcome.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _OutcomeTile(
                        outcome: outcome,
                        selected: _picked == outcome,
                        onTap: () => setState(() {
                          _picked = outcome;
                          _showSuccessGate = false;
                          if (outcome != UssdUserOutcome.success) {
                            _amountMatches = false;
                          }
                        }),
                      ),
                    ),
                  if (_picked == UssdUserOutcome.success) ...[
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _amountMatches,
                      onChanged: (v) =>
                          setState(() => _amountMatches = v ?? false),
                      title: Text(
                        '₹${amount.toStringAsFixed(2)} was debited from my account',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    TextField(
                      controller: _smsRef,
                      decoration: const InputDecoration(
                        labelText: 'Bank SMS ref (optional)',
                        hintText: 'Last 6 digits from debit SMS',
                      ),
                      keyboardType: TextInputType.text,
                    ),
                    if (guard != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        guard,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.warning,
                            ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            GlowButton(
              label: _picked == null
                  ? 'SELECT AN OUTCOME'
                  : 'RECORD: ${_picked!.title}',
              onTap: _picked == null ? null : _submit,
            ),
          ],
        ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.05, curve: Curves.easeOutCubic),
      ),
    );
  }
}

class _OutcomeTile extends StatelessWidget {
  const _OutcomeTile({
    required this.outcome,
    required this.selected,
    required this.onTap,
  });

  final UssdUserOutcome outcome;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HapticScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.hero.withValues(alpha: 0.12)
              : AppColors.surfaceHigh.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.hero : AppColors.surfaceBorder,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              outcome.icon,
              color: selected ? AppColors.hero : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    outcome.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: selected
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    outcome.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textDim,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
