import '../models/semiconductor_models.dart';

/// Plain arithmetic for stock and shortage risk — calculated from recent usage.
abstract final class InventoryEngine {
  static const usageWindowDays = 30;

  static int netStockFromDeltas(
    List<InventoryTransaction> txns, {
    required String chipId,
  }) {
    var stock = 0;
    for (final t in txns.where((e) => e.chipId == chipId)) {
      stock += t.quantityDelta;
    }
    return stock;
  }

  static double averageDailyConsumption(
    List<InventoryTransaction> txns, {
    required String chipId,
    DateTime? now,
  }) {
    final anchor = now ?? DateTime.now();
    final cutoff = anchor.subtract(const Duration(days: usageWindowDays));
    var used = 0;
    for (final t in txns.where((e) => e.chipId == chipId)) {
      if (t.type != InventoryTxnType.used) continue;
      if (!t.timestamp.isBefore(cutoff)) {
        used += t.quantityDelta.abs();
      }
    }
    return used / usageWindowDays;
  }

  static double? daysUntilStockout({
    required int stock,
    required double avgDailyConsumption,
  }) {
    if (avgDailyConsumption <= 0) return null;
    return stock / avgDailyConsumption;
  }

  static StockRiskLevel riskLevel({
    required double? daysUntilStockout,
    required int leadTimeDays,
    required bool hasUsageData,
  }) {
    if (!hasUsageData || daysUntilStockout == null) {
      return StockRiskLevel.insufficientData;
    }
    if (daysUntilStockout < leadTimeDays) return StockRiskLevel.high;
    if (daysUntilStockout < leadTimeDays * 1.5) {
      return StockRiskLevel.medium;
    }
    return StockRiskLevel.low;
  }

  static ChipLiveSnapshot buildSnapshot({
    required SemiconductorChip chip,
    required Supplier supplier,
    required List<InventoryTransaction> txns,
    ChipAlternative? alternative,
    SemiconductorChip? alternativeChip,
    DateTime? now,
  }) {
    final avg = averageDailyConsumption(txns, chipId: chip.chipId, now: now);
    final hasUsage = avg > 0;
    final days = daysUntilStockout(
      stock: chip.quantity,
      avgDailyConsumption: avg,
    );
    final lastTxn = txns.fold<DateTime?>(null, (prev, t) {
      if (t.chipId != chip.chipId) return prev;
      if (prev == null || t.timestamp.isAfter(prev)) return t.timestamp;
      return prev;
    });

    return ChipLiveSnapshot(
      chip: chip,
      supplier: supplier,
      currentStock: chip.quantity,
      avgDailyConsumption: avg,
      daysUntilStockout: days,
      risk: chip.riskLevel,
      hasUsageData: hasUsage,
      alternative: alternative,
      alternativeChip: alternativeChip,
      lastTxnAt: lastTxn,
    );
  }

  static int riskSortOrder(StockRiskLevel risk) {
    return switch (risk) {
      StockRiskLevel.high => 0,
      StockRiskLevel.medium => 1,
      StockRiskLevel.low => 2,
      StockRiskLevel.insufficientData => 3,
    };
  }

  static ({int quantity, String riskLevel}) recalculateState({
    required List<InventoryTransaction> txns,
    required String chipId,
    required int leadTimeDays,
    DateTime? now,
  }) {
    final quantity = netStockFromDeltas(txns, chipId: chipId);
    final avg = averageDailyConsumption(txns, chipId: chipId, now: now);
    final hasUsage = avg > 0;
    final days = daysUntilStockout(stock: quantity, avgDailyConsumption: avg);
    final risk = riskLevel(
      daysUntilStockout: days,
      leadTimeDays: leadTimeDays,
      hasUsageData: hasUsage,
    );
    return (quantity: quantity, riskLevel: risk.dbValue);
  }
}
