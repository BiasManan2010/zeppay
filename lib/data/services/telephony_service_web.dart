import 'dart:async';

import 'package:url_launcher/url_launcher.dart';

import '../../core/platform_detect.dart';
import 'call_visibility_web.dart';
import 'network_info.dart';

/// Web: Android browsers may open *99# via `tel:`; iPhone uses UPI apps instead.
class TelephonyService {
  Future<NetworkInfo> networkInfo() async {
    final ios = platformIsIosWeb;
    return NetworkInfo(
      operator: 'mobile',
      isJio: false,
      networkType: 'cellular',
      recommendedRail: ios ? 'upiIntent' : 'ussd',
      ussdSupported: !ios,
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
