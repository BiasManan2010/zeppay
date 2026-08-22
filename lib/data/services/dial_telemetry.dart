import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local-only log of dial/DTMF outcomes for hackathon field testing.
abstract final class DialTelemetry {
  static const _key = 'zep_dial_telemetry';

  static Future<void> log({
    required String txId,
    required String rail,
    required int amountPaise,
    required bool dtmfAutoSent,
    required bool manualEntryRequired,
    String? manufacturer,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final entry = {
      'txId': txId,
      'rail': rail,
      'amountPaise': amountPaise,
      'dtmfAutoSent': dtmfAutoSent,
      'manualEntryRequired': manualEntryRequired,
      'manufacturer': manufacturer ?? '',
      'at': DateTime.now().toIso8601String(),
    };
    raw.insert(0, jsonEncode(entry));
    if (raw.length > 100) raw.removeRange(100, raw.length);
    await prefs.setStringList(_key, raw);
  }

  static Future<List<Map<String, dynamic>>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => Map<String, dynamic>.from(jsonDecode(s) as Map))
        .toList();
  }
}
