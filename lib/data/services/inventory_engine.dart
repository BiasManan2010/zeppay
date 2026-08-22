import '../models/semiconductor_models.dart';

/// Plain arithmetic for stock and shortage risk — calculated from recent usage.
abstract final class InventoryEngine {
  static const usageWindowDays = 30;

  static int currentStock(
    List<InventoryTransaction> txns, {
    required String chipId,
  }) {
    var stock = 0;
    for (final t in txns.where((e) => e.chipId == chipId)) {
      switch (t.type) {
        case InventoryTxnType.received:
          stock += t.quantity;
        case InventoryTxnType.used:
          stock -= t.quantity;
        case InventoryTxnType.transferred:
          stock -= t.quantity;
      }
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
      if (!t.timestamp.isBefore(cutoff)) used += t.quantity;
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

  static StockRiskLevel? riskLevel({
    required double? daysUntilStockout,
    required int leadTimeDays,
    required bool hasUsageData,
  }) {
    if (!hasUsageData || daysUntilStockout == null) return null;
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
    final stock = currentStock(txns, chipId: chip.chipId);
    final avg = averageDailyConsumption(txns, chipId: chip.chipId, now: now);
    final hasUsage = avg > 0;
    final days = daysUntilStockout(stock: stock, avgDailyConsumption: avg);
    final risk = riskLevel(
      daysUntilStockout: days,
      leadTimeDays: supplier.leadTimeDays,
      hasUsageData: hasUsage,
    );

    return ChipLiveSnapshot(
      chip: chip,
      supplier: supplier,
      currentStock: stock,
      avgDailyConsumption: avg,
      daysUntilStockout: days,
      risk: risk,
      hasUsageData: hasUsage,
      alternative: alternative,
      alternativeChip: alternativeChip,
    );
  }

  static int riskSortOrder(StockRiskLevel? risk) {
    return switch (risk) {
      StockRiskLevel.high => 0,
      StockRiskLevel.medium => 1,
      StockRiskLevel.low => 2,
      null => 3,
    };
  }
}
