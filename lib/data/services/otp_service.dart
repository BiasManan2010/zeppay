import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Twilio Verify via a tiny backend proxy (never embed Twilio auth token in the app).
///
/// Set `--dart-define=TWILIO_VERIFY_URL=https://your-host` to hit the real API.
/// Without it, debug builds accept OTP `123456`.
class OtpService {
  OtpService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const verifyUrl = String.fromEnvironment('TWILIO_VERIFY_URL');

  bool get isLive => verifyUrl.isNotEmpty;

  Future<void> send(String phone) async {
    if (!isLive) {
      debugPrint('OTP dev mode: use 123456 for $phone');
      return;
    }
    final res = await _client.post(
      Uri.parse('$verifyUrl/verify/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
    if (res.statusCode >= 400) {
      throw Exception('Could not send OTP (${res.statusCode})');
    }
  }

  Future<bool> check(String phone, String code) async {
    if (!isLive) {
      return code == '123456';
    }
    final res = await _client.post(
      Uri.parse('$verifyUrl/verify/check'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'code': code}),
    );
    if (res.statusCode >= 400) return false;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['approved'] == true || body['status'] == 'approved';
  }
}
