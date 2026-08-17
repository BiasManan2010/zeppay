import 'dart:async';

/// Non-web: duration is measured by the caller around [TelephonyService.waitForCallEnd].
Future<Duration> waitForDialerReturn({
  Duration timeout = const Duration(minutes: 5),
}) async {
  await Future<void>.delayed(const Duration(seconds: 1));
  return const Duration(seconds: 60);
}
