/// Semiconductor shortage tracking (Challenge 2) — Supabase-backed.

enum InventoryTxnType { received, used, transferred }

enum StockRiskLevel { low, medium, high, insufficientData }

extension InventoryTxnTypeX on InventoryTxnType {
  String get dbValue => name;

  static InventoryTxnType fromDb(String value) {
    return InventoryTxnType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InventoryTxnType.used,
    );
  }
}

extension StockRiskLevelX on StockRiskLevel {
  String get dbValue => switch (this) {
        StockRiskLevel.low => 'LOW',
        StockRiskLevel.medium => 'MEDIUM',
        StockRiskLevel.high => 'HIGH',
        StockRiskLevel.insufficientData => 'INSUFFICIENT_DATA',
      };

  static StockRiskLevel fromDb(String? value) {
    return switch (value?.toUpperCase()) {
      'HIGH' => StockRiskLevel.high,
      'MEDIUM' => StockRiskLevel.medium,
      'LOW' => StockRiskLevel.low,
      'INSUFFICIENT_DATA' => StockRiskLevel.insufficientData,
      _ => StockRiskLevel.insufficientData,
    };
  }
}

/// NFC chip inside every Zep Card (NTAG213 batch) — shown in Settings.
const kZepCardSupplyChipId = 'CHIP001';

class SemiconductorChip {
  const SemiconductorChip({
    required this.chipId,
    required this.partNumber,
    required this.manufacturer,
    required this.category,
    required this.quantity,
    required this.minimumStock,
    required this.supplierId,
    required this.batchId,
    required this.location,
    required this.riskLevel,
  });

  final String chipId;
  final String partNumber;
  final String manufacturer;
  final String category;
  final int quantity;
  final int minimumStock;
  final String supplierId;
  final String batchId;
  final String location;
  final StockRiskLevel riskLevel;

  factory SemiconductorChip.fromJson(Map<String, dynamic> json) {
    return SemiconductorChip(
      chipId: json['chip_id'] as String,
      partNumber: json['part_number'] as String,
      manufacturer: json['manufacturer'] as String,
      category: json['category'] as String,
      quantity: (json['quantity'] as num).toInt(),
      minimumStock: (json['minimum_stock'] as num).toInt(),
      supplierId: json['supplier_id'] as String,
      batchId: json['batch_id'] as String,
      location: json['location'] as String,
      riskLevel: StockRiskLevelX.fromDb(json['risk_level'] as String?),
    );
  }
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

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      supplierId: json['supplier_id'] as String,
      name: json['name'] as String,
      country: json['country'] as String,
      leadTimeDays: (json['lead_time_days'] as num).toInt(),
      reliabilityPct: (json['reliability_pct'] as num).toDouble(),
    );
  }
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

  factory NfcChipTag.fromJson(Map<String, dynamic> json) {
    return NfcChipTag(
      nfcId: json['nfc_id'] as String,
      chipId: json['chip_id'] as String,
      batchId: json['batch_id'] as String,
      assignedAt: DateTime.parse(json['assigned_at'] as String),
      status: json['status'] as String,
    );
  }
}

class InventoryTransaction {
  const InventoryTransaction({
    required this.txnId,
    required this.chipId,
    required this.type,
    required this.quantityDelta,
    required this.timestamp,
  });

  final String txnId;
  final String chipId;
  final InventoryTxnType type;
  final int quantityDelta;
  final DateTime timestamp;

  int get displayQuantity => quantityDelta.abs();

  factory InventoryTransaction.fromJson(Map<String, dynamic> json) {
    return InventoryTransaction(
      txnId: json['txn_id'] as String,
      chipId: json['chip_id'] as String,
      type: InventoryTxnTypeX.fromDb(json['type'] as String),
      quantityDelta: (json['quantity_delta'] as num).toInt(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
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

  factory ChipAlternative.fromJson(Map<String, dynamic> json) {
    return ChipAlternative(
      chipId: json['chip_id'] as String,
      alternativeChipId: json['alternative_chip_id'] as String,
      compatibilityNote: json['compatibility_note'] as String,
    );
  }
}

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
    this.lastTxnAt,
  });

  final SemiconductorChip chip;
  final Supplier supplier;
  final int currentStock;
  final double avgDailyConsumption;
  final double? daysUntilStockout;
  final StockRiskLevel risk;
  final bool hasUsageData;
  final ChipAlternative? alternative;
  final SemiconductorChip? alternativeChip;
  final DateTime? lastTxnAt;
}
