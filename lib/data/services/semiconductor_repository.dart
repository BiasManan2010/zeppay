import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../local/semiconductor_database.dart';
import '../models/semiconductor_models.dart';
import 'inventory_engine.dart';

final semiconductorDbProvider = Provider<SemiconductorDatabase>(
  (ref) => SemiconductorDatabase.instance,
);

final inventoryOverviewProvider =
    FutureProvider<List<ChipLiveSnapshot>>((ref) async {
  final repo = ref.watch(semiconductorDbProvider);
  return SemiconductorRepository(repo).loadOverview();
});

final chipDetailProvider = FutureProvider.family<ChipLiveSnapshot?, String>(
  (ref, chipId) async {
    final repo = ref.watch(semiconductorDbProvider);
    return SemiconductorRepository(repo).loadChipDetail(chipId);
  },
);

final chipTransactionsProvider =
    FutureProvider.family<List<InventoryTransaction>, String>(
  (ref, chipId) async {
    final db = ref.watch(semiconductorDbProvider);
    return db.transactionsForChip(chipId, limit: 10);
  },
);

final nfcTagsProvider = FutureProvider<List<NfcChipTag>>((ref) async {
  final db = ref.watch(semiconductorDbProvider);
  return db.allNfcTags();
});

/// Offline inventory access — no network calls.
class SemiconductorRepository {
  SemiconductorRepository(this._db);

  final SemiconductorDatabase _db;
  static const _uuid = Uuid();

  Future<List<ChipLiveSnapshot>> loadOverview() async {
    final chips = await _db.allChips();
    final txns = await _db.allTransactions();
    final snapshots = <ChipLiveSnapshot>[];

    for (final chip in chips) {
      final supplier = await _db.supplierById(chip.supplierId);
      if (supplier == null) continue;
      snapshots.add(
        InventoryEngine.buildSnapshot(
          chip: chip,
          supplier: supplier,
          txns: txns,
        ),
      );
    }

    snapshots.sort((a, b) {
      final byRisk = InventoryEngine.riskSortOrder(a.risk)
          .compareTo(InventoryEngine.riskSortOrder(b.risk));
      if (byRisk != 0) return byRisk;
      return a.chip.partNumber.compareTo(b.chip.partNumber);
    });
    return snapshots;
  }

  Future<ChipLiveSnapshot?> loadChipDetail(String chipId) async {
    final chip = await _db.chipById(chipId);
    if (chip == null) return null;
    final supplier = await _db.supplierById(chip.supplierId);
    if (supplier == null) return null;
    final txns = await _db.allTransactions();
    final alt = await _db.primaryAlternative(chipId);
    SemiconductorChip? altChip;
    if (alt != null) {
      altChip = await _db.chipById(alt.alternativeChipId);
    }
    return InventoryEngine.buildSnapshot(
      chip: chip,
      supplier: supplier,
      txns: txns,
      alternative: alt,
      alternativeChip: altChip,
    );
  }

  Future<String?> resolveChipIdFromNfc(String nfcId) {
    return _db.chipIdForNfcTag(nfcId);
  }

  Future<void> logTransaction({
    required String chipId,
    required InventoryTxnType type,
    required int quantity,
  }) async {
    await _db.insertTransaction(
      InventoryTransaction(
        txnId: _uuid.v4(),
        chipId: chipId,
        type: type,
        quantity: quantity,
        timestamp: DateTime.now(),
      ),
    );
  }
}
