/// Semiconductor shortage tracking models (Challenge 2).
/// Stock and risk are never stored — only derived from [InventoryTransaction] rows.

enum InventoryTxnType { received, used, transferred }

enum StockRiskLevel { low, medium, high }

extension InventoryTxnTypeX on InventoryTxnType {
  String get dbValue => name;

  static InventoryTxnType fromDb(String value) {
    return InventoryTxnType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InventoryTxnType.used,
    );
  }
}

class SemiconductorChip {
  const SemiconductorChip({
    required this.chipId,
    required this.partNumber,
    required this.manufacturer,
    required this.category,
    required this.minimumStock,
    required this.supplierId,
    required this.batchId,
    required this.location,
  });

  final String chipId;
  final String partNumber;
  final String manufacturer;
  final String category;
  final int minimumStock;
  final String supplierId;
  final String batchId;
  final String location;
}

class Supplier {
  const Supplier({
    required this.supplierId,
    required this.name,
    required this.country,
    required this.leadTimeDays,
    required this.reliabilityPct,
  });

  final String supplierId;
  final String name;
  final String country;
  final int leadTimeDays;
  final double reliabilityPct;
}

class NfcChipTag {
  const NfcChipTag({
    required this.nfcId,
    required this.chipId,
    required this.batchId,
    required this.assignedAt,
    required this.status,
  });

  final String nfcId;
  final String chipId;
  final String batchId;
  final DateTime assignedAt;
  final String status;
}

class InventoryTransaction {
  const InventoryTransaction({
    required this.txnId,
    required this.chipId,
    required this.type,
    required this.quantity,
    required this.timestamp,
  });

  final String txnId;
  final String chipId;
  final InventoryTxnType type;
  final int quantity;
  final DateTime timestamp;
}

class ChipAlternative {
  const ChipAlternative({
    required this.chipId,
    required this.alternativeChipId,
    required this.compatibilityNote,
  });

  final String chipId;
  final String alternativeChipId;
  final String compatibilityNote;
}

/// Live-computed snapshot — always built from the transaction ledger.
class ChipLiveSnapshot {
  const ChipLiveSnapshot({
    required this.chip,
    required this.supplier,
    required this.currentStock,
    required this.avgDailyConsumption,
    required this.daysUntilStockout,
    required this.risk,
    required this.hasUsageData,
    this.alternative,
    this.alternativeChip,
  });

  final SemiconductorChip chip;
  final Supplier supplier;
  final int currentStock;
  final double avgDailyConsumption;
  final double? daysUntilStockout;
  final StockRiskLevel? risk;
  final bool hasUsageData;
  final ChipAlternative? alternative;
  final SemiconductorChip? alternativeChip;
}
