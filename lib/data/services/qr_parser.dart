import '../models/models.dart';

class QrParser {
  /// Decodes a UPI QR / intent locally. Works with zero internet.
  static PaymentDraft? parse(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final lower = value.toLowerCase();
    final upiAt = lower.indexOf('upi://');
    final candidate = upiAt >= 0 ? value.substring(upiAt) : value;

    Uri? uri;
    try {
      uri = Uri.parse(candidate);
    } catch (_) {
      uri = null;
    }

    if (uri != null && uri.scheme.toLowerCase() == 'upi') {
      final pa = _q(uri, 'pa');
      if (pa.isEmpty || !pa.contains('@')) return null;
      return PaymentDraft(
        vpa: pa,
        amountPaise: _paise(_q(uri, 'am')),
        payeeName: _q(uri, 'pn'),
        note: _first(uri, const ['tn', 'tr']),
        source: 'scan',
      );
    }

    if (candidate.contains('@')) {
      final vpa = candidate.split(RegExp(r'\s+')).firstWhere(
        (p) => p.contains('@'),
        orElse: () => '',
      );
      if (vpa.contains('@')) {
        return PaymentDraft(vpa: vpa, amountPaise: 0, source: 'scan');
      }
    }
    return null;
  }

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
