import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'network_info.dart';

/// Result of [RailEngine.resolve]. [rail] is null when offline rails cannot be
/// selected (Android only — never falls back to UPI apps).
class RailResolution {
  const RailResolution({this.rail, this.error});

  final PaymentRail? rail;
  final String? error;

  bool get ok => rail != null && error == null;
}

/// Builds NPCI *99# USSD and UPI 123PAY IVR dial strings from a decoded QR.
class RailEngine {
  /// Jio / 123PAY national IVR. Bank-specific numbers can be swapped later.
  static const ivrNumber = '18008913333';

  /// NPCI BHIM USSD balance enquiry (user still enters UPI PIN in the dialer).
  static const balanceUssd = '*99*3#';

  static const _flakyOems = [
    'samsung',
    'xiaomi',
    'oppo',
    'vivo',
    'redmi',
    'oneplus',
    'realme',
  ];

  /// `upi://pay` intents are allowed on iOS and web only — never on Android.
  static bool allowsUpiIntent(NetworkInfo info) {
    if (info.platform == 'android') return false;
    return info.platform == 'ios' || info.platform == 'web';
  }

  /// Selects the payment rail. On Android, never returns [PaymentRail.upiIntent].
  static RailResolution resolve(NetworkInfo info) {
    if (info.platform == 'unknown') {
      return const RailResolution(
        error:
            "Couldn't detect your carrier — retry or dial *99# manually from Phone.",
      );
    }
    if (info.platform == 'android') {
      if (info.recommendedRail == 'ussd' && info.ussdSupported) {
        return const RailResolution(rail: PaymentRail.ussd);
      }
      return const RailResolution(rail: PaymentRail.ivr);
    }
    if (info.platform == 'web') {
      return const RailResolution(rail: PaymentRail.ussd);
    }
    if (allowsUpiIntent(info)) {
      return const RailResolution(rail: PaymentRail.upiIntent);
    }
    return const RailResolution(
      error: "Couldn't detect your carrier — retry or dial manually",
    );
  }

  @Deprecated('Use resolve()')
  static PaymentRail select(NetworkInfo info) {
    final r = resolve(info);
    assert(
      info.platform != 'android' || r.rail != PaymentRail.upiIntent,
      'Android must never use upiIntent',
    );
    return r.rail ?? PaymentRail.ivr;
  }

  static String encodeVpaForUssd(String vpa) {
    return vpa.replaceAll('.', '*').replaceAll('@', '*');
  }

  /// Whole rupees for USSD — rounded, never truncated for large amounts.
  static int rupeesFromPaise(int amountPaise) {
    return (amountPaise + 50) ~/ 100;
  }

  static String formatUssdAmount(int amountPaise) {
    return rupeesFromPaise(amountPaise).toString();
  }

  /// Send-money-to-UPI-ID shortcut used by BHIM USSD (*99#).
  static String ussdString({required String vpa, required int amountPaise}) {
    final rupees = formatUssdAmount(amountPaise);
    return '*99*1*3*${encodeVpaForUssd(vpa)}*$rupees#';
  }

  /// 123PAY: amount as DTMF after pauses. Uses `;` wait on most OEMs, extra `,,`
  /// on Samsung/Xiaomi/Oppo/Vivo family dialers.
  static String ivrString(
    PaymentDraft draft, {
    String manufacturer = '',
  }) {
    final rupees = rupeesFromPaise(draft.amountPaise);
    final mfg = manufacturer.toLowerCase();
    final flaky = _flakyOems.any(mfg.contains);
    if (flaky) {
      return '$ivrNumber,,,$rupees';
    }
    return '$ivrNumber;$rupees';
  }

  static String ivrScript(PaymentDraft draft) {
    final rupees = formatUssdAmount(draft.amountPaise);
    final who = draft.payeeName.isNotEmpty ? draft.payeeName : draft.vpa;
    return 'When 123PAY answers, confirm ₹$rupees to $who (${draft.vpa}). Amount is pre-dialed.';
  }

  static String dialFor(
    PaymentRail rail,
    PaymentDraft draft, {
    String manufacturer = '',
  }) {
    switch (rail) {
      case PaymentRail.ussd:
        return ussdString(vpa: draft.vpa, amountPaise: draft.amountPaise);
      case PaymentRail.ivr:
        return ivrString(draft, manufacturer: manufacturer);
      case PaymentRail.upiIntent:
        assert(
          kIsWeb || defaultTargetPlatform == TargetPlatform.iOS,
          'upiIntent is iOS/web only',
        );
        return upiUri(draft);
    }
  }

  static String upiUri(PaymentDraft draft) {
    final am = (draft.amountPaise / 100).toStringAsFixed(2);
    final pn = Uri.encodeComponent(draft.payeeName);
    final tn = Uri.encodeComponent(draft.note);
    return 'upi://pay?pa=${draft.vpa}&pn=$pn&am=$am&cu=INR&tn=$tn';
  }
}
