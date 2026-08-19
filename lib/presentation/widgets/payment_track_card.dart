import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/services/payment_tracker.dart';

/// Step checklist for offline USSD payment tracking.
class PaymentTrackCard extends StatelessWidget {
  const PaymentTrackCard({
    super.key,
    required this.steps,
    this.title = 'Payment tracking',
  });

  final List<PaymentTrackStep> steps;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.heroSoft,
                  letterSpacing: 0.6,
                ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < steps.length; i++) ...[
            _TrackRow(step: steps[i]),
            if (i < steps.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 11),
                child: Container(
                  width: 2,
                  height: 10,
                  color: AppColors.surfaceBorder,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({required this.step});

  final PaymentTrackStep step;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (step.state) {
      PaymentTrackStepState.done => (
          Icons.check_circle_rounded,
          AppColors.success,
        ),
      PaymentTrackStepState.active => (
          Icons.radio_button_checked_rounded,
          AppColors.hero,
        ),
      PaymentTrackStepState.todo => (
          Icons.radio_button_unchecked_rounded,
          AppColors.textDim,
        ),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: step.state == PaymentTrackStepState.todo
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
              ),
              if (step.detail.isNotEmpty)
                Text(
                  step.detail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textDim,
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
