import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chrome.dart';
import '../../../core/widgets/zep_components.dart';
import '../../../data/models/semiconductor_models.dart';
import '../../../data/services/semiconductor_repository.dart';
import 'inventory_overview_screen.dart';

class ChipDetailScreen extends ConsumerStatefulWidget {
  const ChipDetailScreen({
    super.key,
    required this.chipId,
    this.fromNfcTap = false,
  });

  final String chipId;
  final bool fromNfcTap;

  @override
  ConsumerState<ChipDetailScreen> createState() => _ChipDetailScreenState();
}

class _ChipDetailScreenState extends ConsumerState<ChipDetailScreen> {
  InventoryTxnType _txnType = InventoryTxnType.used;
  final _qty = TextEditingController(text: '10');
  var _logging = false;

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  Future<void> _logTransaction() async {
    final qty = int.tryParse(_qty.text.trim()) ?? 0;
    if (qty <= 0) return;
    setState(() => _logging = true);
    try {
      final repo = SemiconductorRepository(ref.read(semiconductorDbProvider));
      await repo.logTransaction(
        chipId: widget.chipId,
        type: _txnType,
        quantity: qty,
      );
      HapticFeedback.mediumImpact();
      ref.invalidate(chipDetailProvider(widget.chipId));
      ref.invalidate(chipTransactionsProvider(widget.chipId));
      ref.invalidate(inventoryOverviewProvider);
    } finally {
      if (mounted) setState(() => _logging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(chipDetailProvider(widget.chipId));
    final txns = ref.watch(chipTransactionsProvider(widget.chipId));

    return ZepPage(
      title: 'Chip detail',
      subtitle: widget.fromNfcTap ? 'Opened from NFC batch tag' : null,
      child: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
        data: (snapshot) {
          if (snapshot == null) {
            return const Text('Chip not found in local inventory.');
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            children: [
              ZepDarkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.chip.partNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${snapshot.chip.manufacturer} · ${snapshot.chip.category}',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    _infoRow('Location', snapshot.chip.location),
                    _infoRow('Batch', snapshot.chip.batchId),
                    _infoRow('Min stock', '${snapshot.chip.minimumStock}'),
                    _infoRow(
                      'Supplier',
                      '${snapshot.supplier.name} (${snapshot.supplier.leadTimeDays}d lead)',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ZepDarkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Live stock math',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        RiskBadge(snapshot: snapshot),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _metric('Current stock', '${snapshot.currentStock} units'),
                    _metric(
                      'Avg daily use (30d)',
                      snapshot.hasUsageData
                          ? snapshot.avgDailyConsumption.toStringAsFixed(2)
                          : 'Not enough usage data yet',
                    ),
                    _metric(
                      'Days until stockout',
                      snapshot.hasUsageData && snapshot.daysUntilStockout != null
                          ? snapshot.daysUntilStockout!.toStringAsFixed(1)
                          : '—',
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Calculated from recent usage — never stored as a column.',
                      style: TextStyle(color: AppColors.textDim, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (snapshot.risk == StockRiskLevel.medium ||
                  snapshot.risk == StockRiskLevel.high) ...[
                const SizedBox(height: 12),
                ZepDarkCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Suggested alternative',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (snapshot.alternativeChip != null)
                        Text(
                          snapshot.alternativeChip!.partNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (snapshot.alternative != null)
                        Text(
                          snapshot.alternative!.compatibilityNote,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              ZepDarkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Log transaction',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<InventoryTxnType>(
                      value: _txnType,
                      dropdownColor: AppColors.cardDark,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        labelStyle: TextStyle(color: AppColors.textMuted),
                      ),
                      items: InventoryTxnType.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _txnType = v);
                      },
                    ),
                    TextField(
                      controller: _qty,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        labelStyle: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _logging ? null : _logTransaction,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                      ),
                      child: _logging
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save & recalculate'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Recent ledger',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textOnCream,
                    ),
              ),
              const SizedBox(height: 8),
              txns.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (list) {
                  if (list.isEmpty) {
                    return const Text('No transactions yet.');
                  }
                  return Column(
                    children: list
                        .map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ZepDarkCard(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  formatTxn(t),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(k, style: const TextStyle(color: AppColors.textMuted)),
          const Spacer(),
          Flexible(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
