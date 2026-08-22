import 'package:sqflite/sqflite.dart';

/// Demo seed data for Challenge 2 — Zep Pay's own NFC chip supply chain.
abstract final class SemiconductorSeed {
  static Future<void> apply(Database db) async {
    const suppliers = [
      {
        'supplier_id': 'SUP-DIGI',
        'name': 'DigiKey',
        'country': 'USA',
        'lead_time_days': 21,
        'reliability_pct': 97.5,
      },
      {
        'supplier_id': 'SUP-LCSC',
        'name': 'LCSC',
        'country': 'China',
        'lead_time_days': 14,
        'reliability_pct': 92.0,
      },
      {
        'supplier_id': 'SUP-MOUS',
        'name': 'Mouser',
        'country': 'USA',
        'lead_time_days': 18,
        'reliability_pct': 96.0,
      },
    ];
    for (final s in suppliers) {
      await db.insert('suppliers', s);
    }

    const chips = [
      {
        'chip_id': 'CHIP-NTAG213',
        'part_number': 'NTAG213',
        'manufacturer': 'NXP',
        'category': 'NFC tag IC',
        'minimum_stock': 500,
        'supplier_id': 'SUP-DIGI',
        'batch_id': 'BATCH-NFC-2408',
        'location': 'Zep Pay assembly — Pune',
      },
      {
        'chip_id': 'CHIP-STM32F103',
        'part_number': 'STM32F103C8T6',
        'manufacturer': 'STMicro',
        'category': 'MCU',
        'minimum_stock': 120,
        'supplier_id': 'SUP-MOUS',
        'batch_id': 'BATCH-MCU-2407',
        'location': 'Prototype bench — Bengaluru',
      },
      {
        'chip_id': 'CHIP-ESP32',
        'part_number': 'ESP32-WROOM-32',
        'manufacturer': 'Espressif',
        'category': 'Wi-Fi/BT module',
        'minimum_stock': 80,
        'supplier_id': 'SUP-LCSC',
        'batch_id': 'BATCH-WIFI-2406',
        'location': 'IoT demo shelf',
      },
      {
        'chip_id': 'CHIP-AMS1117',
        'part_number': 'AMS1117-3.3',
        'manufacturer': 'AMS',
        'category': 'LDO regulator',
        'minimum_stock': 300,
        'supplier_id': 'SUP-LCSC',
        'batch_id': 'BATCH-PWR-2405',
        'location': 'SMT reel rack A2',
      },
      {
        'chip_id': 'CHIP-TP4056',
        'part_number': 'TP4056',
        'manufacturer': 'NanJing Top Power',
        'category': 'Li-ion charger IC',
        'minimum_stock': 200,
        'supplier_id': 'SUP-LCSC',
        'batch_id': 'BATCH-CHG-2407',
        'location': 'Power module bin',
      },
      {
        'chip_id': 'CHIP-CH340G',
        'part_number': 'CH340G',
        'manufacturer': 'WCH',
        'category': 'USB-UART bridge',
        'minimum_stock': 150,
        'supplier_id': 'SUP-DIGI',
        'batch_id': 'BATCH-USB-2404',
        'location': 'Dev kit drawer',
      },
      {
        'chip_id': 'CHIP-ATMEGA328',
        'part_number': 'ATmega328P',
        'manufacturer': 'Microchip',
        'category': 'MCU',
        'minimum_stock': 100,
        'supplier_id': 'SUP-MOUS',
        'batch_id': 'BATCH-AVR-2403',
        'location': 'Legacy Arduino stock',
      },
    ];
    for (final c in chips) {
      await db.insert('semiconductors', c);
    }

    const tags = [
      {
        'nfc_id': 'ZEP-TAG-NTAG-01',
        'chip_id': 'CHIP-NTAG213',
        'batch_id': 'BATCH-NFC-2408',
        'assigned_at': '2026-07-01T10:00:00.000',
        'status': 'active',
      },
      {
        'nfc_id': 'ZEP-TAG-STM-01',
        'chip_id': 'CHIP-STM32F103',
        'batch_id': 'BATCH-MCU-2407',
        'assigned_at': '2026-07-15T11:30:00.000',
        'status': 'active',
      },
      {
        'nfc_id': 'ZEP-TAG-ESP-01',
        'chip_id': 'CHIP-ESP32',
        'batch_id': 'BATCH-WIFI-2406',
        'assigned_at': '2026-08-01T09:00:00.000',
        'status': 'active',
      },
    ];
    for (final t in tags) {
      await db.insert('nfc_tags', t);
    }

    const alternatives = [
      {
        'chip_id': 'CHIP-NTAG213',
        'alternative_chip_id': 'CHIP-STM32F103',
        'compatibility_note':
            'Not pin-compatible — use only if NFC batch is delayed; requires PCB respin.',
      },
      {
        'chip_id': 'CHIP-ESP32',
        'alternative_chip_id': 'CHIP-STM32F103',
        'compatibility_note':
            'Different footprint — firmware port needed; lower Wi-Fi throughput.',
      },
      {
        'chip_id': 'CHIP-AMS1117',
        'alternative_chip_id': 'CHIP-TP4056',
        'compatibility_note':
            'Different function — swap only on charger sub-board, not main 3.3V rail.',
      },
    ];
    for (final a in alternatives) {
      await db.insert('alternatives', a);
    }

    await _seedTransactions(db);
  }

  static Future<void> _seedTransactions(Database db) async {
    final now = DateTime.now();
    var txnCounter = 0;

    Future<void> add(
      String chipId,
      String type,
      int qty,
      int daysAgo,
    ) async {
      txnCounter++;
      await db.insert('inventory_transactions', {
        'txn_id': 'SEED-TXN-$txnCounter',
        'chip_id': chipId,
        'type': type,
        'quantity': qty,
        'timestamp': now
            .subtract(Duration(days: daysAgo, hours: txnCounter % 12))
            .toIso8601String(),
      });
    }

    // NTAG213 — tight stock, steady use (demo HIGH risk after a few uses).
    await add('CHIP-NTAG213', 'received', 1200, 28);
    await add('CHIP-NTAG213', 'used', 45, 27);
    await add('CHIP-NTAG213', 'used', 52, 24);
    await add('CHIP-NTAG213', 'used', 48, 21);
    await add('CHIP-NTAG213', 'used', 55, 18);
    await add('CHIP-NTAG213', 'used', 50, 15);
    await add('CHIP-NTAG213', 'used', 47, 12);
    await add('CHIP-NTAG213', 'used', 53, 9);
    await add('CHIP-NTAG213', 'used', 49, 6);
    await add('CHIP-NTAG213', 'used', 51, 3);
    await add('CHIP-NTAG213', 'used', 46, 1);
    await add('CHIP-NTAG213', 'transferred', 30, 5);

    // STM32 — medium buffer
    await add('CHIP-STM32F103', 'received', 400, 29);
    for (var d = 28; d >= 2; d -= 4) {
      await add('CHIP-STM32F103', 'used', 8, d);
    }

    // ESP32 — comfortable
    await add('CHIP-ESP32', 'received', 250, 30);
    for (var d = 25; d >= 5; d -= 5) {
      await add('CHIP-ESP32', 'used', 5, d);
    }

    // AMS1117 — high volume, low use
    await add('CHIP-AMS1117', 'received', 2000, 30);
    await add('CHIP-AMS1117', 'used', 120, 20);
    await add('CHIP-AMS1117', 'used', 90, 10);

    // TP4056
    await add('CHIP-TP4056', 'received', 600, 28);
    await add('CHIP-TP4056', 'used', 25, 14);
    await add('CHIP-TP4056', 'used', 22, 7);

    // CH340G — sparse usage (not enough usage data state)
    await add('CHIP-CH340G', 'received', 300, 25);
    await add('CHIP-CH340G', 'used', 5, 20);

    // ATmega — medium
    await add('CHIP-ATMEGA328', 'received', 350, 27);
    for (var d = 26; d >= 4; d -= 3) {
      await add('CHIP-ATMEGA328', 'used', 6, d);
    }
  }
}
