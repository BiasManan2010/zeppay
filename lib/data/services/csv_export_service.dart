import 'package:collection/collection.dart';
import 'package:csv/csv.dart';

import '../models/models.dart';

class CsvExportService {
  String exportGroup({
    required SplitGroup group,
    required List<Expense> expenses,
    required List<Settlement> settlements,
  }) {
    String name(String id) =>
        group.members.firstWhereOrNull((m) => m.id == id)?.name ?? id;
    final rows = <List<dynamic>>[
      ['Type', 'Date', 'Title', 'Amount', 'Currency', 'Payers', 'Note'],
      ...expenses.map(
        (e) => [
          'expense',
          e.createdAt.toIso8601String(),
          e.title,
          (e.amountPaise / 100).toStringAsFixed(2),
          e.currency,
          e.payerIds.map(name).join('|'),
          e.note,
        ],
      ),
      ...settlements.map(
        (s) => [
          'settlement',
          s.createdAt.toIso8601String(),
          '${name(s.fromId)} → ${name(s.toId)}',
          (s.amountPaise / 100).toStringAsFixed(2),
          'INR',
          s.method,
          s.note,
        ],
      ),
    ];
    return const ListToCsvConverter().convert(rows);
  }
}
