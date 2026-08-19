import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'payment_status_detector.dart';

class PaymentSessionState {
  const PaymentSessionState({
    this.txId,
    this.away,
    this.suggestion,
  });

  final String? txId;
  final Duration? away;
  final TxStatus? suggestion;

  PaymentSessionState copyWith({
    String? txId,
    Duration? away,
    TxStatus? suggestion,
  }) =>
      PaymentSessionState(
        txId: txId ?? this.txId,
        away: away ?? this.away,
        suggestion: suggestion ?? this.suggestion,
      );
}

class PaymentSessionNotifier extends Notifier<PaymentSessionState> {
  @override
  PaymentSessionState build() => const PaymentSessionState();

  void begin(String txId) {
    state = PaymentSessionState(txId: txId);
  }

  void recordReturn(Duration away) {
    state = state.copyWith(
      away: away,
      suggestion: suggestPaymentStatus(away),
    );
  }

  void clear() {
    state = const PaymentSessionState();
  }
}

final paymentSessionProvider =
    NotifierProvider<PaymentSessionNotifier, PaymentSessionState>(
  PaymentSessionNotifier.new,
);
