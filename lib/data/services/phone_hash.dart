import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Matches backend/db.js phoneHash (pepper + SHA-256).
String phoneHashForSupabase(String phone) {
  const pepper = String.fromEnvironment('OTP_PEPPER', defaultValue: 'zeppay');
  final normalized = phone.trim();
  return sha256.convert(utf8.encode('$pepper:$normalized')).toString();
}
