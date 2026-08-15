import '../models/models.dart';

class QrParser {
  /// Decodes NPCI UPI, Bharat QR / EMV, FamPay, GPay, PhonePe, Paytm,
  /// Android `intent://` wrappers, and HTTPS links that carry `pa=`.
  static PaymentDraft? parse(String raw) {
    final value = _unwrap(raw);
    if (value.isEmpty) return null;

    final fromUpi = _fromUpiUri(value);
    if (fromUpi != null) return fromUpi;

    final fromHttp = _fromHttp(value);
    if (fromHttp != null) return fromHttp;

    final fromEmv = _fromEmv(value);
    if (fromEmv != null) return fromEmv;

    final fromQuery = _fromLooseQuery(value);
    if (fromQuery != null) return fromQuery;

    final vpa = _firstVpa(value);
    if (vpa == null) return null;
    return PaymentDraft(vpa: vpa, amountPaise: 0, source: 'scan');
  }

  static String _unwrap(String raw) {
    var value = raw.trim().replaceAll('\r', '').replaceAll('\n', '');
    if (value.isEmpty) return '';
    final intent = value.toLowerCase().indexOf('intent://');
    if (intent >= 0) {
      var body = value.substring(intent + 'intent://'.length);
      final hash = body.indexOf('#');
      if (hash >= 0) body = body.substring(0, hash);
      if (!body.toLowerCase().startsWith('upi:')) {
        body = 'upi://$body';
      }
      return body;
    }
    return value;
  }

  static PaymentDraft? _fromUpiUri(String value) {
    final lower = value.toLowerCase();
    final upiAt = lower.indexOf('upi://');
    if (upiAt < 0) return null;
    var candidate = value.substring(upiAt);
    final end = candidate.indexOf(RegExp(r'[\n\r]'));
    if (end > 0) candidate = candidate.substring(0, end);
    Uri? uri;
    try {
      uri = Uri.parse(candidate);
    } catch (_) {
      uri = null;
    }
    if (uri == null || uri.scheme.toLowerCase() != 'upi') {
      return _fromLooseQuery(candidate);
    }
    final pa = _q(uri, 'pa');
    final vpa = pa.contains('@') ? pa : _firstVpa(candidate);
    if (vpa == null) return null;
    return PaymentDraft(
      vpa: vpa.toLowerCase(),
      amountPaise: _paise(_q(uri, 'am')),
      payeeName: _q(uri, 'pn'),
      note: _first(uri, const ['tn', 'tr', 'purpose']),
      source: 'scan',
    );
  }

  static PaymentDraft? _fromHttp(String value) {
    Uri? uri;
    try {
      uri = Uri.parse(value);
    } catch (_) {
      return null;
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    final pa = _q(uri, 'pa').isNotEmpty ? _q(uri, 'pa') : _q(uri, 'vpa');
    final vpa = pa.contains('@') ? pa : _firstVpa(value);
    if (vpa == null) return null;
    return PaymentDraft(
      vpa: vpa.toLowerCase(),
      amountPaise: _paise(_q(uri, 'am')),
      payeeName: _q(uri, 'pn').isNotEmpty ? _q(uri, 'pn') : _q(uri, 'name'),
      note: _q(uri, 'tn'),
      source: 'scan',
    );
  }

  static PaymentDraft? _fromEmv(String value) {
    final start = value.indexOf('000201');
    final payload = start >= 0 ? value.substring(start) : value;
    final tags = _tlv(payload);
    if (tags.isEmpty) return null;

    String vpa = '';
    String name = tags['59'] ?? '';
    for (final id in tags.keys) {
      final n = int.tryParse(id) ?? 0;
      if (n < 26 || n > 51) continue;
      final nested = _tlv(tags[id]!);
      final direct = nested['01'] ?? nested['02'] ?? '';
      if (direct.contains('@')) {
        vpa = direct.trim();
        break;
      }
      for (final entry in nested.entries) {
        final hit = _firstVpa(entry.value);
        if (hit != null) {
          vpa = hit;
          break;
        }
      }
      if (vpa.isEmpty) {
        final hit = _firstVpa(tags[id]!);
        if (hit != null) vpa = hit;
      }
      if (vpa.isNotEmpty) break;
    }
    vpa = vpa.isNotEmpty ? vpa : (_firstVpa(payload) ?? '');
    if (vpa.isEmpty) return null;
    return PaymentDraft(
      vpa: vpa.toLowerCase(),
      amountPaise: _paise(tags['54'] ?? ''),
      payeeName: name,
      note: tags['62'] ?? '',
      source: 'scan',
    );
  }

  static PaymentDraft? _fromLooseQuery(String value) {
    final qStart = value.indexOf('?');
    if (qStart < 0) return null;
    final query = value.substring(qStart + 1);
    final params = <String, String>{};
    for (final part in query.split('&')) {
      final eq = part.indexOf('=');
      if (eq <= 0) continue;
      final k = Uri.decodeQueryComponent(part.substring(0, eq)).toLowerCase();
      var v = part.substring(eq + 1);
      try {
        v = Uri.decodeQueryComponent(v);
      } catch (_) {}
      params[k] = v;
    }
    final pa = params['pa'] ?? params['vpa'] ?? '';
    final vpa = pa.contains('@') ? pa : _firstVpa(value);
    if (vpa == null) return null;
    return PaymentDraft(
      vpa: vpa.toLowerCase(),
      amountPaise: _paise(params['am'] ?? ''),
      payeeName: params['pn'] ?? params['name'] ?? '',
      note: params['tn'] ?? '',
      source: 'scan',
    );
  }

  static Map<String, String> _tlv(String s) {
    final out = <String, String>{};
    var i = 0;
    while (i + 4 <= s.length) {
      final id = s.substring(i, i + 2);
      if (!RegExp(r'^\d{2}$').hasMatch(id)) break;
      final len = int.tryParse(s.substring(i + 2, i + 4));
      if (len == null || len < 0 || i + 4 + len > s.length) break;
      out[id] = s.substring(i + 4, i + 4 + len);
      i += 4 + len;
    }
    return out;
  }

  static String? _firstVpa(String value) {
    for (var i = 0; i < value.length; i++) {
      if (value[i] != '@') continue;
      var start = i - 1;
      while (start >= 0 && _vpaChar.hasMatch(value[start])) {
        start--;
      }
      start++;
      var end = i + 1;
      while (end < value.length && _hostChar.hasMatch(value[end])) {
        end++;
      }
      var local = value.substring(start, i);
      var host = value.substring(i + 1, end);
      local = local.replaceFirst(RegExp(r'^\d+'), '');
      final localBits = local.split(RegExp(r'\d{2,}'));
      if (localBits.last.length >= 2) local = localBits.last;
      host = host.replaceFirst(RegExp(r'\d.*'), '');
      if (local.length < 2 || host.length < 2) continue;
      if (!_letter.hasMatch(local[0]) || !_letter.hasMatch(host[0])) continue;
      if (host.contains('.')) continue;
      return '$local@$host';
    }
    return null;
  }

  static final _vpaChar = RegExp(r'[a-zA-Z0-9._-]');
  static final _hostChar = RegExp(r'[a-zA-Z0-9.-]');
  static final _letter = RegExp(r'[a-zA-Z]');

  static String _q(Uri uri, String key) {
    for (final e in uri.queryParameters.entries) {
      if (e.key.toLowerCase() == key) return e.value.trim();
    }
    return '';
  }

  static String _first(Uri uri, List<String> keys) {
    for (final k in keys) {
      final v = _q(uri, k);
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  static int _paise(String am) {
    if (am.isEmpty) return 0;
    final n = double.tryParse(am) ?? 0;
    return (n * 100).round();
  }
}
