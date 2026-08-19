import '../models/models.dart';

/// Best-effort status from how long Phone stayed open.
/// Banks do not expose USSD result to a PWA — timing is a hint only, never proof.
TxStatus detectPaymentStatus(Duration away) {
  final s = away.inSeconds;
  if (s < 8) return TxStatus.failed;
  if (s < 20) return TxStatus.pending;
  if (s <= 75) return TxStatus.success;
  if (s <= 120) return TxStatus.pending;
  return TxStatus.failed;
}

TxStatus? suggestPaymentStatus(Duration away) => detectPaymentStatus(away);

String suggestionLabel(TxStatus? status, Duration away) {
  if (status == null) return 'Checking the dialer session…';
  switch (status) {
    case TxStatus.success:
      return 'Typical USSD PIN session (${away.inSeconds}s) — only tap Yes if SMS confirms.';
    case TxStatus.pending:
      return away.inSeconds >= 120
          ? 'You were away ${away.inSeconds}s — likely not finished. Tap pending or failed.'
          : 'Short or long session (${away.inSeconds}s) — confirm from your bank SMS.';
    case TxStatus.failed:
      return away.inSeconds < 8
          ? 'Phone closed immediately — treated as cancelled.'
          : 'Away ${away.inSeconds}s without a normal PIN session — treated as dropped.';
  }
}
