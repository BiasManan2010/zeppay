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

  test('current stock is sum of ledger rows only', () {
    final txns = [
      InventoryTransaction(
        txnId: '1',
        chipId: 'C1',
        type: InventoryTxnType.received,
        quantity: 100,
        timestamp: DateTime(2026, 1, 1),
      ),
      InventoryTransaction(
        txnId: '2',
        chipId: 'C1',
        type: InventoryTxnType.used,
        quantity: 30,
        timestamp: DateTime(2026, 1, 2),
      ),
      InventoryTransaction(
        txnId: '3',
        chipId: 'C1',
        type: InventoryTxnType.transferred,
        quantity: 10,
        timestamp: DateTime(2026, 1, 3),
      ),
    ];
    expect(InventoryEngine.currentStock(txns, chipId: 'C1'), 60);
  });

  test('risk HIGH when stockout before supplier lead time', () {
    const chip = SemiconductorChip(
      chipId: 'C1',
      partNumber: 'X',
      manufacturer: 'Y',
      category: 'MCU',
      minimumStock: 10,
      supplierId: 'S1',
      batchId: 'B1',
      location: 'Shelf',
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
        quantity: 200,
        timestamp: now.subtract(const Duration(days: 29)),
      ),
    ];
    for (var i = 0; i < 30; i++) {
      txns.add(
        InventoryTransaction(
          txnId: 'u$i',
          chipId: 'C1',
          type: InventoryTxnType.used,
          quantity: 5,
          timestamp: now.subtract(Duration(days: 29 - i)),
        ),
      );
    }
    final snap = InventoryEngine.buildSnapshot(
      chip: chip,
      supplier: supplier,
      txns: txns,
      now: now,
    );
    expect(snap.currentStock, 50);
    expect(snap.hasUsageData, isTrue);
    expect(snap.risk, StockRiskLevel.high);
  });

  test('zero usage yields no risk level', () {
    const chip = SemiconductorChip(
      chipId: 'C1',
      partNumber: 'X',
      manufacturer: 'Y',
      category: 'MCU',
      minimumStock: 10,
      supplierId: 'S1',
      batchId: 'B1',
      location: 'Shelf',
    );
    const supplier = Supplier(
      supplierId: 'S1',
      name: 'Test',
      country: 'IN',
      leadTimeDays: 21,
      reliabilityPct: 95,
    );
    final snap = InventoryEngine.buildSnapshot(
      chip: chip,
      supplier: supplier,
      txns: [
        InventoryTransaction(
          txnId: 'r1',
          chipId: 'C1',
          type: InventoryTxnType.received,
          quantity: 500,
          timestamp: DateTime(2026, 1, 1),
        ),
      ],
    );
    expect(snap.hasUsageData, isFalse);
    expect(snap.risk, isNull);
  });
}
