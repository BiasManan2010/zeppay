import '../models/models.dart';

/// Heuristic status when the dialer session ends (no bank API on-device).
TxStatus? suggestPaymentStatus(Duration away) {
  if (away.inSeconds < 4) {
    return TxStatus.failed;
  }
  if (away.inSeconds < 12) {
    return TxStatus.failed;
  }
  if (away.inMinutes >= 4) {
    return TxStatus.failed;
  }
  if (away.inSeconds >= 20 && away.inMinutes < 3) {
    return TxStatus.pending;
  }
  return TxStatus.pending;
}

String suggestionLabel(TxStatus? status, Duration away) {
  if (status == null) return 'Tell us what happened in the dialer.';
  switch (status) {
    case TxStatus.success:
      return 'Looks complete — confirm if money moved.';
    case TxStatus.pending:
      if (away.inSeconds >= 20) {
        return 'You were in the dialer ${away.inSeconds}s — likely pending until your bank SMS confirms.';
      }
      return 'Short session — mark pending if the bank is still processing.';
    case TxStatus.failed:
      if (away.inSeconds < 12) {
        return 'Quick return — payment probably did not start.';
      }
      return 'Long or dropped call — likely failed.';
  }
  return 'Tell us what happened in the dialer.';
}
