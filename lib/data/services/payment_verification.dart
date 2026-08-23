import 'package:flutter/material.dart' show IconData, Icons;

import '../models/models.dart';
import 'payment_tracker.dart';

/// What the user actually saw in Phone / USSD — the only real verdict source.
enum UssdUserOutcome {
  success,
  failed,
  cancelled,
  pending,
  noDial,
}

extension UssdUserOutcomeLabels on UssdUserOutcome {
  String get title => switch (this) {
        UssdUserOutcome.success => 'SUCCESS — money sent',
        UssdUserOutcome.failed => 'FAILED — bank declined',
        UssdUserOutcome.cancelled => 'I cancelled in Phone',
        UssdUserOutcome.pending => 'Still processing / not sure',
        UssdUserOutcome.noDial => 'Never finished USSD steps',
      };

  String get subtitle => switch (this) {
        UssdUserOutcome.success =>
          'USSD or bank SMS confirmed the debit. Only pick this if you are sure.',
        UssdUserOutcome.failed =>
          'Screen said failed, insufficient balance, or wrong PIN.',
        UssdUserOutcome.cancelled =>
          'Hung up or backed out before the bank finished.',
        UssdUserOutcome.pending =>
          'No final message yet — check SMS and confirm later.',
        UssdUserOutcome.noDial =>
          'Phone opened but you did not paste UPI / enter PIN.',
      };

  IconData get icon => switch (this) {
        UssdUserOutcome.success => Icons.check_circle_outline_rounded,
        UssdUserOutcome.failed => Icons.cancel_outlined,
        UssdUserOutcome.cancelled => Icons.call_end_rounded,
        UssdUserOutcome.pending => Icons.hourglass_top_rounded,
        UssdUserOutcome.noDial => Icons.phone_missed_rounded,
      };
}

/// Maps user attestation to ledger status — no timing guesses.
TxStatus statusFromUserOutcome(UssdUserOutcome outcome) {
  return switch (outcome) {
    UssdUserOutcome.success => TxStatus.success,
    UssdUserOutcome.failed => TxStatus.failed,
    UssdUserOutcome.cancelled => TxStatus.failed,
    UssdUserOutcome.pending => TxStatus.pending,
    UssdUserOutcome.noDial => TxStatus.failed,
  };
}

/// Whether success can be recorded — needs outcome + amount match.
bool canConfirmSuccess({
  required UssdUserOutcome? outcome,
  required bool amountMatches,
}) {
  return outcome == UssdUserOutcome.success && amountMatches;
}

String verdictLabel(UssdUserOutcome outcome) {
  return switch (outcome) {
    UssdUserOutcome.success => 'Payment recorded as SUCCESS',
    UssdUserOutcome.failed => 'Payment recorded as FAILED',
    UssdUserOutcome.cancelled => 'Payment recorded as CANCELLED',
    UssdUserOutcome.pending => 'Payment left as PENDING',
    UssdUserOutcome.noDial => 'Payment recorded as NOT COMPLETED',
  };
}

/// Facts only — not a payment judgment.
String sessionContextNote(PaymentTrack track) {
  final parts = <String>[];
  if (track.dialOpenedAt != null) {
    parts.add('Dial opened');
  }
  if (track.longestPhoneStint > Duration.zero) {
    parts.add('${track.longestPhoneStint.inSeconds}s in Phone');
  } else if (track.leftPhoneAt == null) {
    parts.add('No Phone session detected');
  }
  if (track.stintCount > 1) {
    parts.add('${track.stintCount} switches');
  }
  if (parts.isEmpty) return 'Session log empty';
  return parts.join(' · ');
}

/// Warn when timing contradicts a success claim (soft guard, not a block).
String? successGuardMessage({
  required UssdUserOutcome outcome,
  required PaymentTrack track,
}) {
  if (outcome != UssdUserOutcome.success) return null;
  final stint = track.longestPhoneStint.inSeconds;
  if (stint > 0 && stint < 12) {
    return 'Phone was only open ${stint}s — are you sure USSD finished?';
  }
  if (stint == 0) {
    return 'We never saw you leave for Phone — only mark success if SMS confirms.';
  }
  return null;
}
