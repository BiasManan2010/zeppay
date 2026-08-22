import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/semiconductor_models.dart';
import 'inventory_engine.dart';
import 'supabase_service.dart';

final inventoryOverviewProvider =
    FutureProvider<List<ChipLiveSnapshot>>((ref) async {
  return SemiconductorRepository.instance.loadOverview();
});

final chipDetailProvider = FutureProvider.family<ChipLiveSnapshot?, String>(
  (ref, chipId) async {
    return SemiconductorRepository.instance.loadChipDetail(chipId);
  },
);

final chipTransactionsProvider =
    FutureProvider.family<List<InventoryTransaction>, String>(
  (ref, chipId) async {
    return SemiconductorRepository.instance.transactionsForChip(chipId, limit: 10);
  },
);

final nfcTagsProvider = FutureProvider<List<NfcChipTag>>((ref) async {
  return SemiconductorRepository.instance.allNfcTags();
});

final zepCardChipProvider = FutureProvider<ChipLiveSnapshot?>((ref) async {
  return SemiconductorRepository.instance.loadChipDetail(kZepCardSupplyChipId);
});

/// Semiconductor inventory via the shared Supabase project (no local SQLite).
class SemiconductorRepository {
  SemiconductorRepository._();
  static final instance = SemiconductorRepository._();

  void _require() => SupabaseService.instance.requireReady();

  Future<List<SemiconductorChip>> _allChips() async {
    _require();
    final rows = await SupabaseService.instance.client
        .from('semiconductors')
        .select()
        .order('part_number');
    return (rows as List)
        .map((r) => SemiconductorChip.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  Future<SemiconductorChip?> chipById(String chipId) async {
    _require();
    final row = await SupabaseService.instance.client
        .from('semiconductors')
        .select()
        .eq('chip_id', chipId)
        .maybeSingle();
    if (row == null) return null;
    return SemiconductorChip.fromJson(Map<String, dynamic>.from(row));
  }

  Future<Supplier?> supplierById(String supplierId) async {
    _require();
    final row = await SupabaseService.instance.client
        .from('suppliers')
        .select()
        .eq('supplier_id', supplierId)
        .maybeSingle();
    if (row == null) return null;
    return Supplier.fromJson(Map<String, dynamic>.from(row));
  }

  Future<List<InventoryTransaction>> transactionsForChip(
    String chipId, {
    int? limit,
  }) async {
    _require();
    var query = SupabaseService.instance.client
        .from('inventory_transactions')
        .select()
        .eq('chip_id', chipId)
        .order('timestamp', ascending: false);
    if (limit != null) {
      query = query.limit(limit);
    }
    final rows = await query;
    return (rows as List)
        .map((r) => InventoryTransaction.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  Future<List<InventoryTransaction>> _allTransactionsForChip(
    String chipId,
  ) async {
    _require();
    final rows = await SupabaseService.instance.client
        .from('inventory_transactions')
        .select()
        .eq('chip_id', chipId);
    return (rows as List)
        .map((r) => InventoryTransaction.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  Future<ChipAlternative?> primaryAlternative(String chipId) async {
    _require();
    final row = await SupabaseService.instance.client
        .from('alternatives')
        .select()
        .eq('chip_id', chipId)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return ChipAlternative.fromJson(Map<String, dynamic>.from(row));
  }

  Future<List<NfcChipTag>> allNfcTags() async {
    _require();
    final rows = await SupabaseService.instance.client
        .from('nfc_tags')
        .select()
        .order('nfc_id');
    return (rows as List)
        .map((r) => NfcChipTag.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  Future<String?> chipIdForNfcTag(String nfcId) async {
    _require();
    final row = await SupabaseService.instance.client
        .from('nfc_tags')
        .select('chip_id')
        .eq('nfc_id', nfcId)
        .maybeSingle();
    return row?['chip_id'] as String?;
  }

  Future<List<ChipLiveSnapshot>> loadOverview() async {
    final chips = await _allChips();
    final snapshots = <ChipLiveSnapshot>[];

    for (final chip in chips) {
      final snap = await loadChipDetail(chip.chipId);
      if (snap != null) snapshots.add(snap);
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
    final chip = await chipById(chipId);
    if (chip == null) return null;
    final supplier = await supplierById(chip.supplierId);
    if (supplier == null) return null;
    final txns = await _allTransactionsForChip(chipId);
    final alt = await primaryAlternative(chipId);
    SemiconductorChip? altChip;
    if (alt != null) {
      altChip = await chipById(alt.alternativeChipId);
    }
    return InventoryEngine.buildSnapshot(
      chip: chip,
      supplier: supplier,
      txns: txns,
      alternative: alt,
      alternativeChip: altChip,
    );
  }

  Future<void> logTransaction({
    required String chipId,
    required InventoryTxnType type,
    required int quantity,
  }) async {
    _require();
    final delta = switch (type) {
      InventoryTxnType.received => quantity,
      InventoryTxnType.used => -quantity,
      InventoryTxnType.transferred => -quantity,
    };

    await SupabaseService.instance.client.from('inventory_transactions').insert({
      'chip_id': chipId,
      'type': type.dbValue,
      'quantity_delta': delta,
    });

    final chip = await chipById(chipId);
    final supplier = await supplierById(chip!.supplierId);
    final txns = await _allTransactionsForChip(chipId);
    final state = InventoryEngine.recalculateState(
      txns: txns,
      chipId: chipId,
      leadTimeDays: supplier!.leadTimeDays,
    );

    await SupabaseService.instance.client.from('semiconductors').update({
      'quantity': state.quantity,
      'risk_level': state.riskLevel,
    }).eq('chip_id', chipId);
  }
}
