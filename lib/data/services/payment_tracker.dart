import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'payment_verification.dart';

/// Lifecycle of one offline USSD payment attempt.
enum PaymentTrackPhase {
  started,
  upiCopied,
  dialOpened,
  inPhone,
  returned,
  awaitingConfirm,
  resolved,
}

class PaymentTrack {
  const PaymentTrack({
    required this.txId,
    required this.refCode,
    required this.vpa,
    required this.amountPaise,
    required this.startedAt,
    this.phase = PaymentTrackPhase.started,
    this.upiCopiedAt,
    this.dialOpenedAt,
    this.dialString = '',
    this.leftPhoneAt,
    this.returnedAt,
    this.longestPhoneStint = Duration.zero,
    this.stintCount = 0,
    this.userOutcome,
    this.userSmsRef = '',
    this.amountConfirmed = false,
    this.resolvedStatus,
  });

  final String txId;
  final String refCode;
  final String vpa;
  final int amountPaise;
  final DateTime startedAt;
  final PaymentTrackPhase phase;
  final DateTime? upiCopiedAt;
  final DateTime? dialOpenedAt;
  final String dialString;
  final DateTime? leftPhoneAt;
  final DateTime? returnedAt;
  final Duration longestPhoneStint;
  final int stintCount;
  final UssdUserOutcome? userOutcome;
  final String userSmsRef;
  final bool amountConfirmed;
  final TxStatus? resolvedStatus;

  /// Deprecated timing hint — not shown as judgment in UI.
  TxStatus? get suggestion => null;

  bool get needsConfirmation =>
      phase == PaymentTrackPhase.awaitingConfirm && resolvedStatus == null;

  Duration? get away => longestPhoneStint > Duration.zero
      ? longestPhoneStint
      : (returnedAt != null && leftPhoneAt != null
          ? returnedAt!.difference(leftPhoneAt!)
          : null);

  PaymentTrack copyWith({
    PaymentTrackPhase? phase,
    DateTime? upiCopiedAt,
    DateTime? dialOpenedAt,
    String? dialString,
    DateTime? leftPhoneAt,
    DateTime? returnedAt,
    Duration? longestPhoneStint,
    int? stintCount,
    UssdUserOutcome? userOutcome,
    String? userSmsRef,
    bool? amountConfirmed,
    TxStatus? resolvedStatus,
  }) =>
      PaymentTrack(
        txId: txId,
        refCode: refCode,
        vpa: vpa,
        amountPaise: amountPaise,
        startedAt: startedAt,
        phase: phase ?? this.phase,
        upiCopiedAt: upiCopiedAt ?? this.upiCopiedAt,
        dialOpenedAt: dialOpenedAt ?? this.dialOpenedAt,
        dialString: dialString ?? this.dialString,
        leftPhoneAt: leftPhoneAt ?? this.leftPhoneAt,
        returnedAt: returnedAt ?? this.returnedAt,
        longestPhoneStint: longestPhoneStint ?? this.longestPhoneStint,
        stintCount: stintCount ?? this.stintCount,
        userOutcome: userOutcome ?? this.userOutcome,
        userSmsRef: userSmsRef ?? this.userSmsRef,
        amountConfirmed: amountConfirmed ?? this.amountConfirmed,
        resolvedStatus: resolvedStatus ?? this.resolvedStatus,
      );

  Map<String, dynamic> toJson() => {
        'txId': txId,
        'refCode': refCode,
        'vpa': vpa,
        'amountPaise': amountPaise,
        'startedAt': startedAt.toIso8601String(),
        'phase': phase.name,
        'upiCopiedAt': upiCopiedAt?.toIso8601String(),
        'dialOpenedAt': dialOpenedAt?.toIso8601String(),
        'dialString': dialString,
        'leftPhoneAt': leftPhoneAt?.toIso8601String(),
        'returnedAt': returnedAt?.toIso8601String(),
        'longestPhoneStintMs': longestPhoneStint.inMilliseconds,
        'stintCount': stintCount,
        'userOutcome': userOutcome?.name,
        'userSmsRef': userSmsRef,
        'amountConfirmed': amountConfirmed,
        'resolvedStatus': resolvedStatus?.name,
      };

  factory PaymentTrack.fromJson(Map<String, dynamic> j) {
    TxStatus? parseStatus(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      for (final s in TxStatus.values) {
        if (s.name == raw) return s;
      }
      return null;
    }

    PaymentTrackPhase phase = PaymentTrackPhase.started;
    for (final p in PaymentTrackPhase.values) {
      if (p.name == j['phase']) {
        phase = p;
        break;
      }
    }

    UssdUserOutcome? parseOutcome(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      for (final o in UssdUserOutcome.values) {
        if (o.name == raw) return o;
      }
      return null;
    }

    return PaymentTrack(
      txId: j['txId'] as String? ?? '',
      refCode: j['refCode'] as String? ?? '',
      vpa: j['vpa'] as String? ?? '',
      amountPaise: j['amountPaise'] as int? ?? 0,
      startedAt:
          DateTime.tryParse(j['startedAt'] as String? ?? '') ?? DateTime.now(),
      phase: phase,
      upiCopiedAt: DateTime.tryParse(j['upiCopiedAt'] as String? ?? ''),
      dialOpenedAt: DateTime.tryParse(j['dialOpenedAt'] as String? ?? ''),
      dialString: j['dialString'] as String? ?? '',
      leftPhoneAt: DateTime.tryParse(j['leftPhoneAt'] as String? ?? ''),
      returnedAt: DateTime.tryParse(j['returnedAt'] as String? ?? ''),
      longestPhoneStint:
          Duration(milliseconds: j['longestPhoneStintMs'] as int? ?? 0),
      stintCount: j['stintCount'] as int? ?? 0,
      userOutcome: parseOutcome(j['userOutcome'] as String?),
      userSmsRef: j['userSmsRef'] as String? ?? '',
      amountConfirmed: j['amountConfirmed'] as bool? ?? false,
      resolvedStatus: parseStatus(j['resolvedStatus'] as String?),
    );
  }
}

class PaymentTrackStore {
  PaymentTrackStore(this._prefs);

  static const _key = 'zep_payment_track';

  final SharedPreferences _prefs;

  PaymentTrack? load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return PaymentTrack.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(PaymentTrack? track) async {
    if (track == null) {
      await _prefs.remove(_key);
      return;
    }
    await _prefs.setString(_key, jsonEncode(track.toJson()));
  }
}

/// Dial session timing facts — no automatic payment verdict.
List<PaymentTrackStep> trackSteps(PaymentTrack track) {
  final phase = track.phase;
  PaymentTrackStepState s(PaymentTrackPhase need) {
    if (phase.index > need.index) return PaymentTrackStepState.done;
    if (phase == need) return PaymentTrackStepState.active;
    return PaymentTrackStepState.todo;
  }

  String phoneDetail() {
    if (track.longestPhoneStint > Duration.zero) {
      return '${track.longestPhoneStint.inSeconds}s in Phone';
    }
    if (track.leftPhoneAt != null && track.returnedAt == null) {
      return 'In Phone now…';
    }
    return 'Opens *99*1*3';
  }

  String confirmDetail() {
    if (track.userOutcome != null) {
      return track.userOutcome!.title;
    }
    return 'Tell us what USSD showed';
  }

  return [
    PaymentTrackStep(
      label: 'UPI ID copied',
      detail: track.vpa,
      state: s(PaymentTrackPhase.upiCopied),
    ),
    PaymentTrackStep(
      label: '*99*1*3 dialed',
      detail: track.dialString.isEmpty ? 'Send-to-UPI USSD' : track.dialString,
      state: s(PaymentTrackPhase.dialOpened),
    ),
    PaymentTrackStep(
      label: 'Phone session',
      detail: phoneDetail(),
      state: phase.index >= PaymentTrackPhase.returned.index
          ? PaymentTrackStepState.done
          : phase == PaymentTrackPhase.inPhone
              ? PaymentTrackStepState.active
              : PaymentTrackStepState.todo,
    ),
    PaymentTrackStep(
      label: 'You confirm',
      detail: confirmDetail(),
      state: phase == PaymentTrackPhase.awaitingConfirm
          ? PaymentTrackStepState.active
          : phase == PaymentTrackPhase.resolved
              ? PaymentTrackStepState.done
              : PaymentTrackStepState.todo,
    ),
  ];
}

enum PaymentTrackStepState { todo, active, done }

class PaymentTrackStep {
  const PaymentTrackStep({
    required this.label,
    required this.detail,
    required this.state,
  });

  final String label;
  final String detail;
  final PaymentTrackStepState state;
}
