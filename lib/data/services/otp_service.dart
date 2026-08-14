import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Twilio Verify via a tiny backend proxy (never embed Twilio auth token in the app).
///
/// URL resolution order:
/// 1. Saved Settings URL (`twilio_verify_url`)
/// 2. `--dart-define=TWILIO_VERIFY_URL=https://host`
/// 3. Live Render proxy `https://zeppay.onrender.com`
///
/// If the URL is cleared, debug OTP `123456` is accepted.
class OtpService {
  OtpService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const compiledUrl = String.fromEnvironment(
    'TWILIO_VERIFY_URL',
    defaultValue: 'https://zeppay.onrender.com',
  );
  static const prefsKey = 'twilio_verify_url';

  Future<String> resolveUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = (prefs.getString(prefsKey) ?? '').trim();
    final raw = saved.isNotEmpty ? saved : compiledUrl.trim();
    return raw.replaceAll(RegExp(r'/+$'), '');
  }

  Future<bool> isLive() async => (await resolveUrl()).isNotEmpty;

  Future<void> saveUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, url.trim().replaceAll(RegExp(r'/+$'), ''));
  }

  Future<Map<String, dynamic>> health() async {
    final base = await resolveUrl();
    if (base.isEmpty) return const {'ok': false};
    try {
      final res = await _client
          .get(Uri.parse('$base/health'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode >= 500) return {'ok': false};
      final body = jsonDecode(res.body);
      if (body is Map) return Map<String, dynamic>.from(body);
      return {'ok': res.statusCode < 500};
    } catch (_) {
      return const {'ok': false};
    }
  }

  Future<bool> ping() async {
    final h = await health();
    return h['ok'] == true || h['twilio'] == true || h['supabase'] == true;
  }

  Future<void> send(String phone) async {
    final base = await resolveUrl();
    if (base.isEmpty) {
      debugPrint('OTP dev mode: use 123456 for $phone');
      return;
    }
    final res = await _client
        .post(
          Uri.parse('$base/verify/start'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone}),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode >= 400) {
      throw Exception(_err(res, 'Could not send OTP'));
    }
  }

  Future<bool> check(String phone, String code) async {
    final base = await resolveUrl();
    if (base.isEmpty) {
      return code == '123456';
    }
    final res = await _client
        .post(
          Uri.parse('$base/verify/check'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone, 'code': code}),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode >= 400) return false;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['approved'] == true || body['status'] == 'approved';
  }

  String _err(http.Response res, String fallback) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['error'] != null) return '${body['error']}';
    } catch (_) {}
    return '$fallback (${res.statusCode})';
  }
}
