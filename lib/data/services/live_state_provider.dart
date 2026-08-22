import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/app_store.dart';
import '../models/models.dart';
import '../models/semiconductor_models.dart';
import 'semiconductor_repository.dart';
import 'supabase_service.dart';
import 'user_card_repository.dart';

/// Freshly computed live-state snapshot — no caching beyond this fetch.
class LiveStateSnapshot {
  const LiveStateSnapshot({
    required this.completedTxCount,
    required this.zepCoinBalance,
    required this.pendingRequestsCount,
    required this.asOf,
    this.hasZepCard = false,
    this.chipRiskLevel,
    this.chipTransactionCount,
    this.supabaseConfigured = false,
    this.supabaseFetchError,
  });

  final int completedTxCount;
  final int zepCoinBalance;
  final int pendingRequestsCount;
  final DateTime asOf;
  final bool hasZepCard;
  final String? chipRiskLevel;
  final int? chipTransactionCount;
  final bool supabaseConfigured;
  final String? supabaseFetchError;
}

/// Loads all live values at the moment of fetch — autoDispose refetches on open.
final liveStateProvider =
    FutureProvider.autoDispose<LiveStateSnapshot>((ref) async {
  // Re-run when local ledger changes while this screen is open.
  final app = ref.watch(appStoreProvider);

  final completedTxCount = app.transactions
      .where((t) => t.status == TxStatus.success)
      .length;
  final pendingRequestsCount = app.requests
      .where((r) => r.status == RequestStatus.pending)
      .length;

  var hasZepCard = false;
  String? chipRiskLevel;
  int? chipTransactionCount;
  String? supabaseFetchError;
  final supabaseConfigured = SupabaseService.instance.isReady;

  if (supabaseConfigured) {
    try {
      final phone = app.sessionPhone;
      if (phone != null && phone.isNotEmpty) {
        final card = await UserCardRepository.instance.cardForPhone(phone);
        if (card != null) {
          hasZepCard = true;
          final chipId =
              await UserCardRepository.instance.chipIdForNfc(card.nfcId);
          if (chipId != null) {
            final detail =
                await SemiconductorRepository.instance.loadChipDetail(chipId);
            final txns = await SemiconductorRepository.instance
                .transactionsForChip(chipId);
            if (detail != null) {
              chipRiskLevel = _riskLabel(detail.risk);
            }
            chipTransactionCount = txns.length;
          }
        }
      }
    } catch (e) {
      supabaseFetchError = e.toString();
    }
  }

  return LiveStateSnapshot(
    completedTxCount: completedTxCount,
    zepCoinBalance: app.zepCoinBalance,
    pendingRequestsCount: pendingRequestsCount,
    asOf: DateTime.now(),
    hasZepCard: hasZepCard,
    chipRiskLevel: chipRiskLevel,
    chipTransactionCount: chipTransactionCount,
    supabaseConfigured: supabaseConfigured,
    supabaseFetchError: supabaseFetchError,
  );
});

String _riskLabel(StockRiskLevel risk) {
  return switch (risk) {
    StockRiskLevel.high => 'HIGH',
    StockRiskLevel.medium => 'MEDIUM',
    StockRiskLevel.low => 'LOW',
    StockRiskLevel.insufficientData => 'INSUFFICIENT_DATA',
  };
}
