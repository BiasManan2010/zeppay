import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';

enum SecurityEventKind {
  sessionStart,
  otpVerified,
  paymentAuthorized,
  dialOpened,
  dialReturned,
  paymentResolved,
  logout,
}

class SecurityEvent {
  const SecurityEvent({
    required this.kind,
    required this.at,
    this.txId,
    this.detail = '',
    this.chain = '',
  });

  final SecurityEventKind kind;
  final DateTime at;
  final String? txId;
  final String detail;
  final String chain;

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'at': at.toIso8601String(),
        'txId': txId,
        'detail': detail,
        'chain': chain,
      };

  factory SecurityEvent.fromJson(Map<String, dynamic> j) {
    final kindName = j['kind'] as String? ?? '';
    var kind = SecurityEventKind.sessionStart;
    for (final k in SecurityEventKind.values) {
      if (k.name == kindName) {
        kind = k;
        break;
      }
    }
    return SecurityEvent(
      kind: kind,
      at: DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime.now(),
      txId: j['txId'] as String?,
      detail: j['detail'] as String? ?? '',
      chain: j['chain'] as String? ?? '',
    );
  }
}

/// Local tamper-evident audit trail + short-lived payment authorization.
class SecurityAudit {
  SecurityAudit(this._prefs);

  static const _logKey = 'zep_sec_audit';
  static const _tokenKey = 'zep_sec_token';
  static const _authKey = 'zep_sec_auth_at';
  static const _maxEntries = 200;
  static const _authWindow = Duration(minutes: 45);

  final SharedPreferences _prefs;
  final _uuid = const Uuid();

  String? get sessionToken => _prefs.getString(_tokenKey);

  Future<void> onOtpVerified(String phone) async {
    final token = _uuid.v4();
    await _prefs.setString(_tokenKey, token);
    await _prefs.setString(_authKey, DateTime.now().toIso8601String());
    await _log(
      SecurityEventKind.otpVerified,
      detail: _maskPhone(phone),
    );
  }

  Future<bool> authorizePayment({
    required int amountPaise,
    required String txId,
    required String vpa,
  }) async {
    if (!_sessionFresh) {
      return false;
    }
    await _prefs.setString(_authKey, DateTime.now().toIso8601String());
    await _log(
      SecurityEventKind.paymentAuthorized,
      txId: txId,
      detail: '₹${amountPaise / 100} → $vpa',
    );
    return true;
  }

  Future<void> dialOpened(String txId, String dial) async {
    await _log(
      SecurityEventKind.dialOpened,
      txId: txId,
      detail: dial.length > 48 ? '${dial.substring(0, 48)}…' : dial,
    );
  }

  Future<void> dialReturned(String txId, Duration away, TxStatus? suggestion) async {
    await _log(
      SecurityEventKind.dialReturned,
      txId: txId,
      detail: '${away.inSeconds}s · suggest ${suggestion?.name ?? 'none'}',
    );
  }

  Future<void> paymentResolved(String txId, TxStatus status) async {
    await _log(
      SecurityEventKind.paymentResolved,
      txId: txId,
      detail: status.name,
    );
  }

  Future<void> logout() async {
    await _log(SecurityEventKind.logout);
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_authKey);
  }

  List<SecurityEvent> recent({int limit = 40}) {
    final raw = _prefs.getString(_logKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map(SecurityEvent.fromJson)
          .toList();
      return list.take(limit).toList();
    } catch (_) {
      return const [];
    }
  }

  bool get _sessionFresh {
    final raw = _prefs.getString(_authKey);
    if (raw == null) return false;
    final at = DateTime.tryParse(raw);
    if (at == null) return false;
    return DateTime.now().difference(at) < _authWindow;
  }

  Future<void> _log(
    SecurityEventKind kind, {
    String? txId,
    String detail = '',
  }) async {
    final prev = _prefs.getString(_logKey);
    var chainSeed = '';
    if (prev != null && prev.isNotEmpty) {
      try {
        final last = (jsonDecode(prev) as List).last as Map<String, dynamic>;
        chainSeed = last['chain'] as String? ?? '';
      } catch (_) {}
    }
    final at = DateTime.now();
    final payload = '${chainSeed}|${kind.name}|${at.toIso8601String()}|$txId|$detail';
    final chain = sha256.convert(utf8.encode(payload)).toString();
    final event = SecurityEvent(
      kind: kind,
      at: at,
      txId: txId,
      detail: detail,
      chain: chain,
    );
    final entries = recent(limit: _maxEntries);
    final next = [event, ...entries].take(_maxEntries).map((e) => e.toJson()).toList();
    await _prefs.setString(_logKey, jsonEncode(next));
  }

  String _maskPhone(String phone) {
    final d = phone.replaceAll(RegExp(r'\D'), '');
    if (d.length < 4) return 'phone';
    return '+${d.substring(0, d.length - 4)}****';
  }
}

final securityAuditProvider = FutureProvider<SecurityAudit>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return SecurityAudit(prefs);
});
