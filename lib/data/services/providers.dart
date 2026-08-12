import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'biometric_service.dart';
import 'otp_service.dart';
import 'telephony_service.dart';

final otpServiceProvider = Provider((_) => OtpService());
final biometricServiceProvider = Provider((_) => BiometricService());
final telephonyServiceProvider = Provider((_) => TelephonyService());

final paymentDraftProvider = StateProvider<PaymentDraft?>((_) => null);
final pendingPhoneProvider = StateProvider<String>((_) => '');
final lastRailProvider = StateProvider<PaymentRail?>((_) => null);

final networkInfoProvider = FutureProvider((ref) {
  return ref.watch(telephonyServiceProvider).networkInfo();
});

Future<void> hapticTap() async {
  await HapticFeedback.lightImpact();
}

Future<void> hapticLock() async {
  await HapticFeedback.mediumImpact();
}
