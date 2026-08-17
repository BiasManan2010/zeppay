import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'biometric_service.dart';
import 'contacts_access.dart';
import 'otp_service.dart';
import 'telephony_service.dart';
import 'security_audit.dart';
import 'payment_session.dart';

final otpServiceProvider = Provider((_) => OtpService());
final biometricServiceProvider = Provider((_) => BiometricService());
final telephonyServiceProvider = Provider((_) => TelephonyService());

final paymentDraftProvider = StateProvider<PaymentDraft?>((_) => null);
final pendingPhoneProvider = StateProvider<String>((_) => '');
final lastRailProvider = StateProvider<PaymentRail?>((_) => null);
final pendingTxIdProvider = StateProvider<String?>((_) => null);

final otpLiveProvider = FutureProvider((ref) {
  return ref.watch(otpServiceProvider).isLive();
});

final phoneContactsProvider = FutureProvider((ref) {
  return ContactsAccess.load(requestIfNeeded: false);
});

void startPayment(
  WidgetRef ref, {
  required String vpa,
  required int amountPaise,
  String payeeName = '',
  String note = '',
  String source = 'pay',
  String category = 'other',
  String? requestId,
  String? settleGroupId,
  String? settleFromId,
  String? settleToId,
}) {
  ref.read(paymentDraftProvider.notifier).state = PaymentDraft(
    vpa: vpa,
    amountPaise: amountPaise,
    payeeName: payeeName,
    note: note,
    source: source,
    category: category,
    requestId: requestId,
    settleGroupId: settleGroupId,
    settleFromId: settleFromId,
    settleToId: settleToId,
  );
}

final networkInfoProvider = FutureProvider((ref) {
  return ref.watch(telephonyServiceProvider).networkInfo();
});

Future<void> hapticTap() async {
  await HapticFeedback.lightImpact();
}

Future<void> hapticLock() async {
  await HapticFeedback.mediumImpact();
}
