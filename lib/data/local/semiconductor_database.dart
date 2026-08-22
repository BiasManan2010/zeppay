import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/semiconductor_models.dart';
import 'semiconductor_seed.dart';

/// Local SQLite store for semiconductor inventory (separate from AppStore).
class SemiconductorDatabase {
  SemiconductorDatabase._();
  static final instance = SemiconductorDatabase._();

  Database? _db;
  final _lock = Completer<void>()..complete();

  Future<Database> get database async {
    if (_db != null) return _db!;
    await _lock.future;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'zeppay_semiconductor.db');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE semiconductors (
            chip_id TEXT PRIMARY KEY,
            part_number TEXT NOT NULL,
            manufacturer TEXT NOT NULL,
            category TEXT NOT NULL,
            minimum_stock INTEGER NOT NULL,
            supplier_id TEXT NOT NULL,
            batch_id TEXT NOT NULL,
            location TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE suppliers (
            supplier_id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            country TEXT NOT NULL,
            lead_time_days INTEGER NOT NULL,
            reliability_pct REAL NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE nfc_tags (
            nfc_id TEXT PRIMARY KEY,
            chip_id TEXT NOT NULL,
            batch_id TEXT NOT NULL,
            assigned_at TEXT NOT NULL,
            status TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE inventory_transactions (
            txn_id TEXT PRIMARY KEY,
            chip_id TEXT NOT NULL,
            type TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE alternatives (
            chip_id TEXT NOT NULL,
            alternative_chip_id TEXT NOT NULL,
            compatibility_note TEXT NOT NULL,
            PRIMARY KEY (chip_id, alternative_chip_id)
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_inv_txn_chip ON inventory_transactions(chip_id)',
        );
        await db.execute(
          'CREATE INDEX idx_inv_txn_time ON inventory_transactions(timestamp)',
        );
        // Demo seed data — fictional Zep Pay NFC supply chain.
        await SemiconductorSeed.apply(db);
      },
    );
    return db;
  }

  Future<List<SemiconductorChip>> allChips() async {
    final db = await database;
    final rows = await db.query('semiconductors', orderBy: 'part_number ASC');
    return rows.map(_chipFromRow).toList();
  }

  Future<SemiconductorChip?> chipById(String chipId) async {
    final db = await database;
    final rows = await db.query(
      'semiconductors',
      where: 'chip_id = ?',
      whereArgs: [chipId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _chipFromRow(rows.first);
  }

  Future<String?> chipIdForNfcTag(String nfcId) async {
    final db = await database;
    final rows = await db.query(
      'nfc_tags',
      where: 'nfc_id = ?',
      whereArgs: [nfcId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['chip_id'] as String;
  }

  Future<Supplier?> supplierById(String supplierId) async {
    final db = await database;
    final rows = await db.query(
      'suppliers',
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _supplierFromRow(rows.first);
  }

  Future<List<InventoryTransaction>> transactionsForChip(
    String chipId, {
    int? limit,
  }) async {
    final db = await database;
    final rows = await db.query(
      'inventory_transactions',
      where: 'chip_id = ?',
      whereArgs: [chipId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map(_txnFromRow).toList();
  }

  Future<List<InventoryTransaction>> allTransactions() async {
    final db = await database;
    final rows = await db.query('inventory_transactions');
    return rows.map(_txnFromRow).toList();
  }

  Future<ChipAlternative?> primaryAlternative(String chipId) async {
    final db = await database;
    final rows = await db.query(
      'alternatives',
      where: 'chip_id = ?',
      whereArgs: [chipId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return ChipAlternative(
      chipId: row['chip_id'] as String,
      alternativeChipId: row['alternative_chip_id'] as String,
      compatibilityNote: row['compatibility_note'] as String,
    );
  }

  Future<List<NfcChipTag>> allNfcTags() async {
    final db = await database;
    final rows = await db.query('nfc_tags', orderBy: 'nfc_id ASC');
    return rows
        .map(
          (r) => NfcChipTag(
            nfcId: r['nfc_id'] as String,
            chipId: r['chip_id'] as String,
            batchId: r['batch_id'] as String,
            assignedAt: DateTime.parse(r['assigned_at'] as String),
            status: r['status'] as String,
          ),
        )
        .toList();
  }

  Future<void> insertTransaction(InventoryTransaction txn) async {
    final db = await database;
    await db.insert('inventory_transactions', {
      'txn_id': txn.txnId,
      'chip_id': txn.chipId,
      'type': txn.type.dbValue,
      'quantity': txn.quantity,
      'timestamp': txn.timestamp.toIso8601String(),
    });
  }

  SemiconductorChip _chipFromRow(Map<String, Object?> row) {
    return SemiconductorChip(
      chipId: row['chip_id'] as String,
      partNumber: row['part_number'] as String,
      manufacturer: row['manufacturer'] as String,
      category: row['category'] as String,
      minimumStock: row['minimum_stock'] as int,
      supplierId: row['supplier_id'] as String,
      batchId: row['batch_id'] as String,
      location: row['location'] as String,
    );
  }

  Supplier _supplierFromRow(Map<String, Object?> row) {
    return Supplier(
      supplierId: row['supplier_id'] as String,
      name: row['name'] as String,
      country: row['country'] as String,
      leadTimeDays: row['lead_time_days'] as int,
      reliabilityPct: (row['reliability_pct'] as num).toDouble(),
    );
  }

  InventoryTransaction _txnFromRow(Map<String, Object?> row) {
    return InventoryTransaction(
      txnId: row['txn_id'] as String,
      chipId: row['chip_id'] as String,
      type: InventoryTxnTypeX.fromDb(row['type'] as String),
      quantity: row['quantity'] as int,
      timestamp: DateTime.parse(row['timestamp'] as String),
    );
  }
}
