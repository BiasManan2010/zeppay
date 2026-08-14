import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/platform.dart';

class NetworkInfo {
  const NetworkInfo({
    required this.operator,
    required this.isJio,
    required this.networkType,
    required this.recommendedRail,
    required this.ussdSupported,
    required this.platform,
  });

  final String operator;
  final bool isJio;
  final String networkType;
  final String recommendedRail;
  final bool ussdSupported;
  final String platform;

  factory NetworkInfo.unknown() => const NetworkInfo(
        operator: 'unknown',
        isJio: false,
        networkType: 'unknown',
        recommendedRail: 'ivr',
        ussdSupported: false,
        platform: 'unknown',
      );

  factory NetworkInfo.fromMap(Map<dynamic, dynamic> m) => NetworkInfo(
        operator: m['operator'] as String? ?? '',
        isJio: m['isJio'] as bool? ?? false,
        networkType: m['networkType'] as String? ?? 'unknown',
        recommendedRail: m['recommendedRail'] as String? ?? 'ivr',
        ussdSupported: m['ussdSupported'] as bool? ?? false,
        platform: m['platform'] as String? ?? 'android',
      );
}

class TelephonyService {
  static const _methods = MethodChannel('in.zeppay/telephony');
  static const _events = EventChannel('in.zeppay/call_state');

  Stream<Map<dynamic, dynamic>> callStates() {
    if (!isAndroidDevice) return const Stream.empty();
    return _events.receiveBroadcastStream().map((e) => Map<dynamic, dynamic>.from(e as Map));
  }

  Future<NetworkInfo> networkInfo() async {
    if (!isAndroidDevice) {
      return const NetworkInfo(
        operator: 'ios',
        isJio: false,
        networkType: 'n/a',
        recommendedRail: 'upiIntent',
        ussdSupported: false,
        platform: 'ios',
      );
    }
    try {
      final raw = await _methods.invokeMethod<Map<dynamic, dynamic>>('getNetworkInfo');
      if (raw == null) return NetworkInfo.unknown();
      return NetworkInfo.fromMap(raw);
    } catch (e) {
      debugPrint('networkInfo failed: $e');
      return NetworkInfo.unknown();
    }
  }

  Future<void> requestPermissions() async {
    if (!isAndroidDevice) return;
    await _methods.invokeMethod('requestPermissions');
  }

  Future<bool> hasCallPermission() async {
    if (!isAndroidDevice) return false;
    return await _methods.invokeMethod<bool>('hasCallPermission') ?? false;
  }

  Future<void> dial(String number) async {
    if (!isAndroidDevice) {
      throw UnsupportedError('Offline rails are Android-only');
    }
    await _methods.invokeMethod('dial', {'number': number});
  }

  Future<void> waitForCallEnd({Duration timeout = const Duration(minutes: 5)}) async {
    if (!isAndroidDevice) return;
    await callStates().firstWhere((e) => e['ended'] == true).timeout(timeout);
  }
}
