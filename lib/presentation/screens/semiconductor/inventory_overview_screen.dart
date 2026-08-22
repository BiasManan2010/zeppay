import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chrome.dart';
import '../../../core/widgets/zep_components.dart';
import '../../../data/models/semiconductor_models.dart';
import '../../../data/services/semiconductor_repository.dart';

class InventoryOverviewScreen extends ConsumerWidget {
  const InventoryOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inventoryOverviewProvider);

    return ZepPage(
      title: 'Chip shortage tracker',
      subtitle:
          'Challenge 2 — live stock from Supabase, synced after every transaction',
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Could not load inventory: $e'),
        data: (snapshots) {
          final high =
              snapshots.where((s) => s.risk == StockRiskLevel.high).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            children: [
              ZepDarkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$high at HIGH risk',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: high > 0 ? AppColors.danger : Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${snapshots.length} tracked batches · sorted by shortage risk',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...snapshots.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ChipRow(
                    snapshot: s,
                    onTap: () => context.push('/chip/${s.chip.chipId}'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.push('/chip-tag-setup'),
                icon: const Icon(Icons.nfc_rounded),
                label: const Text('Write demo chip tag'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.snapshot, required this.onTap});

  final ChipLiveSnapshot snapshot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chip = snapshot.chip;
    return ZepDarkCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chip.partNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${chip.manufacturer} · ${chip.category}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Stock ${snapshot.currentStock} · '
                  '${snapshot.hasUsageData ? '${snapshot.avgDailyConsumption.toStringAsFixed(1)}/day' : 'no recent use'}',
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          RiskBadge(snapshot: snapshot),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.snapshot});

  final ChipLiveSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final label = riskLabel(snapshot);
    final color = riskColor(snapshot);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

String riskLabel(ChipLiveSnapshot snapshot) {
  return switch (snapshot.risk) {
    StockRiskLevel.high => 'HIGH',
    StockRiskLevel.medium => 'MEDIUM',
    StockRiskLevel.low => 'LOW',
    StockRiskLevel.insufficientData => 'NO DATA',
  };
}

Color riskColor(ChipLiveSnapshot snapshot) {
  return switch (snapshot.risk) {
    StockRiskLevel.high => AppColors.danger,
    StockRiskLevel.medium => AppColors.warning,
    StockRiskLevel.low => AppColors.success,
    StockRiskLevel.insufficientData => AppColors.textMuted,
  };
}

String formatTxn(InventoryTransaction t) {
  final fmt = DateFormat('d MMM, h:mm a');
  final type = switch (t.type) {
    InventoryTxnType.received => 'Received',
    InventoryTxnType.used => 'Used',
    InventoryTxnType.transferred => 'Transferred',
  };
  return '$type ${t.displayQuantity} · ${fmt.format(t.timestamp)}';
}
