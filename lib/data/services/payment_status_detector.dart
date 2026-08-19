import '../models/models.dart';

/// Best-effort status from how long Phone stayed open.
/// Banks do not expose USSD result to a PWA — this is session timing only.
TxStatus detectPaymentStatus(Duration away) {
  final s = away.inSeconds;
  if (s < 8) return TxStatus.failed;
  if (s < 18) return TxStatus.pending;
  if (s <= 180) return TxStatus.success;
  if (s <= 300) return TxStatus.pending;
  return TxStatus.failed;
}

TxStatus? suggestPaymentStatus(Duration away) => detectPaymentStatus(away);

String suggestionLabel(TxStatus? status, Duration away) {
  if (status == null) return 'Checking the dialer session…';
  switch (status) {
    case TxStatus.success:
      return 'You stayed in Phone long enough for a PIN — marking paid. Check SMS if unsure.';
    case TxStatus.pending:
      return 'Short or long session (${away.inSeconds}s) — holding as pending until you confirm in History.';
    case TxStatus.failed:
      return away.inSeconds < 8
          ? 'Phone closed immediately — treated as cancelled.'
          : 'Session ran too long — treated as dropped.';
  }
}
