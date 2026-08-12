import '../models/models.dart';

class QrParser {
  /// Decodes a UPI QR / intent locally. Works with zero internet.
  static PaymentDraft? parse(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    Uri? uri;
    try {
      uri = Uri.parse(value);
    } catch (_) {
      uri = null;
    }

    if (uri != null && (uri.scheme == 'upi' || uri.scheme == 'UPILITE')) {
      final pa = uri.queryParameters['pa'] ?? uri.queryParameters['pn'] ?? '';
      if (pa.isEmpty) return null;
      final am = _paise(uri.queryParameters['am']);
      return PaymentDraft(
        vpa: pa,
        amountPaise: am,
        payeeName: uri.queryParameters['pn'] ?? '',
        note: uri.queryParameters['tn'] ?? uri.queryParameters['tr'] ?? '',
      );
    }

    if (value.contains('@')) {
      return PaymentDraft(vpa: value, amountPaise: 0);
    }
    return null;
  }

  static int _paise(String? am) {
    if (am == null || am.isEmpty) return 0;
    final n = double.tryParse(am) ?? 0;
    return (n * 100).round();
  }
}
