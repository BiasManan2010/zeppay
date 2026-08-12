import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

import '../models/models.dart';

class CsvExportService {
  Future<File> exportGroup({
    required SplitGroup group,
    required List<Expense> expenses,
    required List<Settlement> settlements,
  }) async {
    final rows = <List<dynamic>>[
      ['Type', 'Date', 'Title', 'Amount', 'Currency', 'Payers', 'Note'],
      ...expenses.map(
        (e) => [
          'expense',
          e.createdAt.toIso8601String(),
          e.title,
          (e.amountPaise / 100).toStringAsFixed(2),
          e.currency,
          e.payerIds.join('|'),
          e.note,
        ],
      ),
      ...settlements.map(
        (s) => [
          'settlement',
          s.createdAt.toIso8601String(),
          '${s.fromId} → ${s.toId}',
          (s.amountPaise / 100).toStringAsFixed(2),
          'INR',
          s.method,
          '',
        ],
      ),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${group.name.replaceAll(' ', '_')}_ledger.csv');
    return file.writeAsString(csv);
  }
}
