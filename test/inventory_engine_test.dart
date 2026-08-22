import 'package:flutter_test/flutter_test.dart';
import 'package:zeppay/data/models/chip_tag_codec.dart';
import 'package:zeppay/data/models/semiconductor_models.dart';
import 'package:zeppay/data/services/inventory_engine.dart';

void main() {
  test('ChipTagCodec round-trips nfc id', () {
    const id = 'ZEP-TAG-NTAG-01';
    final uri = ChipTagCodec.appUri(nfcId: id);
    expect(ChipTagCodec.parseUri(uri), id);
  });

  test('net stock is sum of quantity_delta rows', () {
    final txns = [
      InventoryTransaction(
        txnId: '1',
        chipId: 'C1',
        type: InventoryTxnType.received,
        quantityDelta: 100,
        timestamp: DateTime(2026, 1, 1),
      ),
      InventoryTransaction(
        txnId: '2',
        chipId: 'C1',
        type: InventoryTxnType.used,
        quantityDelta: -30,
        timestamp: DateTime(2026, 1, 2),
      ),
      InventoryTransaction(
        txnId: '3',
        chipId: 'C1',
        type: InventoryTxnType.transferred,
        quantityDelta: -10,
        timestamp: DateTime(2026, 1, 3),
      ),
    ];
    expect(InventoryEngine.netStockFromDeltas(txns, chipId: 'C1'), 60);
  });

  test('risk HIGH when stockout before supplier lead time', () {
    final chip = SemiconductorChip(
      chipId: 'C1',
      partNumber: 'X',
      manufacturer: 'Y',
      category: 'MCU',
      quantity: 50,
      minimumStock: 10,
      supplierId: 'S1',
      batchId: 'B1',
      location: 'Shelf',
      riskLevel: StockRiskLevel.high,
    );
    const supplier = Supplier(
      supplierId: 'S1',
      name: 'Test',
      country: 'IN',
      leadTimeDays: 21,
      reliabilityPct: 95,
    );
    final now = DateTime(2026, 8, 22);
    final txns = <InventoryTransaction>[
      InventoryTransaction(
        txnId: 'r1',
        chipId: 'C1',
        type: InventoryTxnType.received,
        quantityDelta: 200,
        timestamp: now.subtract(const Duration(days: 29)),
      ),
    ];
    for (var i = 0; i < 30; i++) {
      txns.add(
        InventoryTransaction(
          txnId: 'u$i',
          chipId: 'C1',
          type: InventoryTxnType.used,
          quantityDelta: -5,
          timestamp: now.subtract(Duration(days: 29 - i)),
        ),
      );
    }
    final state = InventoryEngine.recalculateState(
      txns: txns,
      chipId: 'C1',
      leadTimeDays: supplier.leadTimeDays,
      now: now,
    );
    expect(state.quantity, 50);
    expect(state.riskLevel, 'HIGH');

    final snap = InventoryEngine.buildSnapshot(
      chip: chip.copyWith(quantity: state.quantity, riskLevel: StockRiskLevel.high),
      supplier: supplier,
      txns: txns,
      now: now,
    );
    expect(snap.currentStock, 50);
    expect(snap.hasUsageData, isTrue);
    expect(snap.risk, StockRiskLevel.high);
  });

  test('zero usage yields INSUFFICIENT_DATA risk', () {
    final chip = SemiconductorChip(
      chipId: 'C1',
      partNumber: 'X',
      manufacturer: 'Y',
      category: 'MCU',
      quantity: 500,
      minimumStock: 10,
      supplierId: 'S1',
      batchId: 'B1',
      location: 'Shelf',
      riskLevel: StockRiskLevel.insufficientData,
    );
    const supplier = Supplier(
      supplierId: 'S1',
      name: 'Test',
      country: 'IN',
      leadTimeDays: 21,
      reliabilityPct: 95,
    );
    final txns = [
      InventoryTransaction(
        txnId: 'r1',
        chipId: 'C1',
        type: InventoryTxnType.received,
        quantityDelta: 500,
        timestamp: DateTime(2026, 1, 1),
      ),
    ];
    final state = InventoryEngine.recalculateState(
      txns: txns,
      chipId: 'C1',
      leadTimeDays: supplier.leadTimeDays,
    );
    expect(state.riskLevel, 'INSUFFICIENT_DATA');

    final snap = InventoryEngine.buildSnapshot(
      chip: chip,
      supplier: supplier,
      txns: txns,
    );
    expect(snap.hasUsageData, isFalse);
    expect(snap.risk, StockRiskLevel.insufficientData);
  });
}

extension on SemiconductorChip {
  SemiconductorChip copyWith({
    int? quantity,
    StockRiskLevel? riskLevel,
  }) {
    return SemiconductorChip(
      chipId: chipId,
      partNumber: partNumber,
      manufacturer: manufacturer,
      category: category,
      quantity: quantity ?? this.quantity,
      minimumStock: minimumStock,
      supplierId: supplierId,
      batchId: batchId,
      location: location,
      riskLevel: riskLevel ?? this.riskLevel,
    );
  }
}
