import 'dart:async';

import 'package:url_launcher/url_launcher.dart';

import 'dial_return.dart';
import 'network_info.dart';

/// iPhone PWA: open Phone with *99# / 123PAY via `tel:` and watch return.
class TelephonyService {
  Future<NetworkInfo> networkInfo() async {
    return const NetworkInfo(
      operator: 'mobile',
      isJio: false,
      networkType: 'cellular',
      recommendedRail: 'ussd',
      ussdSupported: true,
      platform: 'web',
    );
  }

  Future<void> requestPermissions() async {}

  Future<bool> hasCallPermission() async => true;

  Future<void> dial(String number) async {
    final uri = Uri.parse(_telUri(number));
    final ok = await launchUrl(uri);
    if (!ok) {
      throw Exception('Could not open the Phone dialer. Tap the number manually.');
    }
  }

  String _telUri(String dial) {
    final encoded = dial.replaceAll('#', '%23');
    return 'tel:$encoded';
  }

  Future<void> waitForCallEnd({
    Duration timeout = const Duration(minutes: 5),
  }) async {
    await waitForDialerReturn(timeout: timeout);
  }
}
