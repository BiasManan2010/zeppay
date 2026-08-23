import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../motion/app_motion.dart';
import '../theme/app_colors.dart';

/// Goal-gradient bar. [done] / [total] should never start at 0.
class GoalBar extends StatelessWidget {
  const GoalBar({
    super.key,
    required this.done,
    required this.total,
    required this.label,
  });

  final int done;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = (done / total).clamp(0.08, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            Text(
              '$done / $total',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.heroSoft,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.08, end: t),
            duration: AppMotion.slow,
            curve: AppMotion.out,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 6,
              backgroundColor: AppColors.surfaceHigh,
              color: AppColors.hero,
            ),
          ),
        ),
      ],
    );
  }
}

class GiftNote extends StatelessWidget {
  const GiftNote({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hero.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.heroSoft, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LossNote extends StatelessWidget {
  const LossNote({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.warning,
        height: 1.35,
      ),
    );
  }
}

/// Live card the user is assembling (IKEA / endowment).
class ZepCardPreview extends StatelessWidget {
  const ZepCardPreview({
    super.key,
    required this.name,
    required this.handle,
    required this.bank,
  });

  final String name;
  final String handle;
  final String bank;

  @override
  Widget build(BuildContext context) {
    final show = name.trim().isEmpty ? 'Your name' : name.trim();
    return AnimatedContainer(
      duration: AppMotion.fast,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppColors.scanCard,
        border: Border.all(color: AppColors.hero.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR ZEP CARD',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.heroSoft,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            show,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            handle.contains('@') ? handle : 'handle@upi',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            bank.isEmpty ? 'Bank' : bank,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class ChoicePills extends StatelessWidget {
  const ChoicePills({
    super.key,
    required this.options,
    required this.selected,
    required this.onPick,
  });

  final List<(String id, String label)> options;
  final String selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          ChoiceChip(
            selected: selected == o.$1,
            label: Text(o.$2),
            onSelected: (_) {
              HapticFeedback.selectionClick();
              onPick(o.$1);
            },
          ),
      ],
    );
  }
}
