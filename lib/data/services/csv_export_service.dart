import 'package:csv/csv.dart';

import '../models/models.dart';

class CsvExportService {
  String exportGroup({
    required SplitGroup group,
    required List<Expense> expenses,
    required List<Settlement> settlements,
  }) {
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
    return const ListToCsvConverter().convert(rows);
  }
}
