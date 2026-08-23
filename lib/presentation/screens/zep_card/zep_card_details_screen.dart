import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chrome.dart';
import '../../../core/widgets/upi_reveal_row.dart';
import '../../../core/widgets/zep_components.dart';
import '../../../core/widgets/zep_physical_card.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/semiconductor_models.dart';
import '../../../data/services/semiconductor_repository.dart';
import '../../../data/services/supabase_service.dart';
import '../../../data/services/user_card_repository.dart';
import 'chip_risk_ui.dart';

class ZepCardDetailsScreen extends ConsumerStatefulWidget {
  const ZepCardDetailsScreen({super.key});

  @override
  ConsumerState<ZepCardDetailsScreen> createState() =>
      _ZepCardDetailsScreenState();
}

class _ZepCardDetailsScreenState extends ConsumerState<ZepCardDetailsScreen> {
  final _nameEdit = TextEditingController();
  var _editingName = false;
  var _savingName = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(userCardProvider);
    });
  }

  Future<void> _refreshChip(String? chipId) async {
    ref.invalidate(userCardProvider);
    if (chipId != null) {
      ref.invalidate(chipDetailProvider(chipId));
      ref.invalidate(chipTransactionsProvider(chipId));
    }
    await ref.read(userCardProvider.future);
  }

  @override
  void dispose() {
    _nameEdit.dispose();
    super.dispose();
  }

  Future<void> _saveName(String phone) async {
    setState(() => _savingName = true);
    try {
      await UserCardRepository.instance.updateCardName(
        phone: phone,
        cardName: _nameEdit.text.trim(),
      );
      ref.invalidate(userCardProvider);
      if (mounted) setState(() => _editingName = false);
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(appStoreProvider).profile;
    final phone = ref.watch(appStoreProvider).sessionPhone ?? '';
    final cardAsync = ref.watch(userCardProvider);
    final upiId = profile?.upiId ?? '';

    return ZepPage(
      title: 'Card Details',
      subtitle: 'Your Zep Card and the live status of the chip inside it.',
      child: cardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Could not load card: $e'),
        data: (card) {
          if (card == null) {
            return Column(
              children: [
                const Text('No Zep Card linked yet.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/get-zep-card'),
                  child: const Text('Get / Claim Zep Card'),
                ),
              ],
            );
          }

          if (!_editingName && _nameEdit.text != card.cardName) {
            _nameEdit.text = card.cardName;
          }

          final chipAsync = ref.watch(userCardChipIdProvider);
          return RefreshIndicator(
            onRefresh: () async {
              final chipId = await ref.read(userCardChipIdProvider.future);
              await _refreshChip(chipId);
            },
            child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              ZepPhysicalCard(
                cardholderName: card.cardName,
                onTap: () {},
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: UpiRevealRow(upiId: upiId),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ZepDarkCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Card ownership',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _infoRow('Cardholder', card.cardName),
                      _infoRow('NFC tag', card.nfcId),
                      _infoRow(
                        'Claimed',
                        DateFormat('d MMM yyyy, h:mm a').format(card.claimedAt),
                      ),
                      _infoRow('Status', card.status),
                      const SizedBox(height: 8),
                      if (_editingName)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _nameEdit,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: 'Name on card',
                                  labelStyle: TextStyle(color: AppColors.textMuted),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _savingName
                                  ? null
                                  : () => _saveName(phone),
                              icon: const Icon(Icons.check_rounded,
                                  color: AppColors.success),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _editingName = false),
                              icon: const Icon(Icons.close_rounded,
                                  color: AppColors.textMuted),
                            ),
                          ],
                        )
                      else
                        TextButton.icon(
                          onPressed: () => setState(() => _editingName = true),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit name on card'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'The NFC chip inside your card is a tracked semiconductor component — here\'s its live status.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textOnCreamMuted,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              chipAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    SupabaseService.instance.isReady
                        ? 'Chip data unavailable: $e'
                        : 'Configure Supabase to see live chip tracking.',
                  ),
                ),
                data: (chipId) {
                  if (chipId == null) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No chip linked to this NFC tag.'),
                    );
                  }
                  return _ChipTrackingSection(chipId: chipId);
                },
              ),
            ],
          ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipTrackingSection extends ConsumerWidget {
  const _ChipTrackingSection({required this.chipId});

  final String chipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(chipDetailProvider(chipId));
    final txns = ref.watch(chipTransactionsProvider(chipId));

    return detail.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error loading chip: $e'),
      ),
      data: (snapshot) {
        if (snapshot == null) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Chip not found in inventory.'),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              ZepDarkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            snapshot.chip.partNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        RiskBadge(snapshot: snapshot),
                      ],
                    ),
                    Text(
                      '${snapshot.chip.manufacturer} · batch ${snapshot.chip.batchId}',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    _metric('Current stock (your chip type)', '${snapshot.currentStock} units'),
                    _metric(
                      'Risk level',
                      riskLabel(snapshot),
                    ),
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
                  ],
                ),
              ),
              const SizedBox(height: 12),
              txns.when(
                loading: () => const ZepDarkCard(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => ZepDarkCard(child: Text('Transactions: $e')),
                data: (list) => ZepDarkCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent inventory moves (${list.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (list.isEmpty)
                        const Text(
                          'No transactions recorded for this chip yet.',
                          style: TextStyle(color: AppColors.textMuted),
                        )
                      else
                        ...list.take(6).map((t) => _txnRow(t)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.textMuted)),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _txnRow(InventoryTransaction t) {
    final fmt = DateFormat('d MMM, HH:mm');
    final sign = t.quantityDelta >= 0 ? '+' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            switch (t.type) {
              InventoryTxnType.received => Icons.south_west_rounded,
              InventoryTxnType.used => Icons.north_east_rounded,
              InventoryTxnType.transferred => Icons.swap_horiz_rounded,
            },
            size: 16,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${t.type.name} · $sign${t.quantityDelta}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Text(
            fmt.format(t.timestamp),
            style: const TextStyle(color: AppColors.textDim, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
