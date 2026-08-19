import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'dial_session.dart';
import 'payment_tracker.dart';
import 'payment_verification.dart';

class PaymentSessionState {
  const PaymentSessionState({this.track});

  final PaymentTrack? track;

  Duration? get away => track?.away;

  TxStatus? get suggestion => track?.suggestion;

  PaymentSessionState copyWith({PaymentTrack? track}) =>
      PaymentSessionState(track: track);
}

class PaymentSessionNotifier extends AsyncNotifier<PaymentSessionState> {
  PaymentTrackStore? _store;

  @override
  Future<PaymentSessionState> build() async {
    final prefs = await SharedPreferences.getInstance();
    _store = PaymentTrackStore(prefs);
    final saved = _store!.load();
    return PaymentSessionState(track: saved);
  }

  Future<void> _persist(PaymentTrack? track) async {
    await _store?.save(track);
    state = AsyncData(PaymentSessionState(track: track));
  }

  Future<void> begin({
    required String txId,
    required String refCode,
    required String vpa,
    required int amountPaise,
  }) async {
    final track = PaymentTrack(
      txId: txId,
      refCode: refCode,
      vpa: vpa,
      amountPaise: amountPaise,
      startedAt: DateTime.now(),
    );
    await _persist(track);
  }

  Future<void> markUpiCopied() async {
    final track = state.value?.track;
    if (track == null) return;
    await _persist(
      track.copyWith(
        phase: PaymentTrackPhase.upiCopied,
        upiCopiedAt: DateTime.now(),
      ),
    );
  }

  Future<void> markDialOpened(String dial) async {
    final track = state.value?.track;
    if (track == null) return;
    await _persist(
      track.copyWith(
        phase: PaymentTrackPhase.dialOpened,
        dialOpenedAt: DateTime.now(),
        dialString: dial,
      ),
    );
  }

  Future<void> markInPhone() async {
    final track = state.value?.track;
    if (track == null) return;
    await _persist(
      track.copyWith(
        phase: PaymentTrackPhase.inPhone,
        leftPhoneAt: DateTime.now(),
      ),
    );
  }

  Future<void> recordDialSession(DialSessionReport session) async {
    final track = state.value?.track;
    if (track == null) return;
    await _persist(
      track.copyWith(
        phase: PaymentTrackPhase.awaitingConfirm,
        leftPhoneAt: session.leftAt ?? track.leftPhoneAt,
        returnedAt: session.returnedAt ?? DateTime.now(),
        longestPhoneStint: session.longestStint,
        stintCount: session.stintCount,
      ),
    );
  }

  Future<void> recordUserVerification({
    required UssdUserOutcome outcome,
    String smsRef = '',
    bool amountConfirmed = false,
  }) async {
    final track = state.value?.track;
    if (track == null) return;
    await _persist(
      track.copyWith(
        userOutcome: outcome,
        userSmsRef: smsRef.trim(),
        amountConfirmed: amountConfirmed,
      ),
    );
  }

  Future<void> markAwaitingConfirm() async {
    final track = state.value?.track;
    if (track == null) return;
    await _persist(
      track.copyWith(phase: PaymentTrackPhase.awaitingConfirm),
    );
  }

  Future<void> resolve(TxStatus status) async {
    final track = state.value?.track;
    if (track == null) return;
    await _persist(
      track.copyWith(
        phase: PaymentTrackPhase.resolved,
        resolvedStatus: status,
      ),
    );
    await _persist(null);
  }

  Future<void> clear() async {
    await _persist(null);
  }

  PaymentTrack? get activeTrack {
    final track = state.value?.track;
    if (track == null) return null;
    if (track.phase == PaymentTrackPhase.resolved) return null;
    return track;
  }
}

final paymentSessionProvider =
    AsyncNotifierProvider<PaymentSessionNotifier, PaymentSessionState>(
  PaymentSessionNotifier.new,
);

final paymentTrackProvider = Provider<PaymentTrack?>((ref) {
  return ref.watch(paymentSessionProvider).value?.track;
});
