import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';

class ReceiptShare {
  static String text(TxRecord tx) {
    final when = DateFormat('d MMM y, h:mm a').format(tx.createdAt);
    final who = tx.payeeName.isEmpty ? tx.vpa : tx.payeeName;
    final status = switch (tx.status) {
      TxStatus.success => 'SUCCESSFUL',
      TxStatus.pending => 'PENDING',
      TxStatus.failed => 'FAILED',
    };
    return [
      'Zep Pay',
      'Payment $status',
      '₹${(tx.amountPaise / 100).toStringAsFixed(2)}',
      'To: $who',
      'UPI: ${tx.vpa}',
      if (tx.note.isNotEmpty) 'Note: ${tx.note}',
      'Zep Pay ID: ${tx.refCode.isEmpty ? tx.id : tx.refCode}',
      when,
      tx.offline ? 'Rail: ${tx.rail.name} (offline)' : 'Rail: UPI intent',
      '',
      'This ID is stored on your phone. It is not an NPCI UTR.',
    ].join('\n');
  }

  static Future<void> share(TxRecord tx) async {
    await Share.share(text(tx));
  }

  static Future<void> copy(TxRecord tx) async {
    await Clipboard.setData(ClipboardData(text: text(tx)));
  }
}
