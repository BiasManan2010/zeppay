import 'dial_session.dart';

/// Non-web: duration is measured by the caller around [TelephonyService.waitForCallEnd].
Future<DialSessionReport> waitForDialerReturn({
  Duration timeout = const Duration(minutes: 5),
}) async {
  await Future<void>.delayed(const Duration(seconds: 1));
  return DialSessionReport(
    longestStint: const Duration(seconds: 60),
    totalHidden: const Duration(seconds: 60),
    stintCount: 1,
    returnedAt: DateTime.now(),
  );
}
