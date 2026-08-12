import '../models/models.dart';
import 'telephony_service.dart';

/// Builds NPCI *99# USSD and UPI 123PAY IVR dial strings from a decoded QR.
class RailEngine {
  /// Jio / 123PAY national IVR. Bank-specific numbers can be swapped later.
  static const ivrNumber = '18008913333';

  static String encodeVpaForUssd(String vpa) {
    return vpa.replaceAll('.', '*').replaceAll('@', '*');
  }

  /// Send-money-to-UPI-ID shortcut used by BHIM USSD (*99#).
  static String ussdString({required String vpa, required int amountPaise}) {
    final rupees = (amountPaise / 100).toStringAsFixed(0);
    return '*99*1*3*${encodeVpaForUssd(vpa)}*$rupees#';
  }

  static String ivrString() => ivrNumber;

  static String dialFor(PaymentRail rail, PaymentDraft draft) {
    switch (rail) {
      case PaymentRail.ussd:
        return ussdString(vpa: draft.vpa, amountPaise: draft.amountPaise);
      case PaymentRail.ivr:
        return ivrString();
      case PaymentRail.upiIntent:
        return upiUri(draft);
    }
  }

  static String upiUri(PaymentDraft draft) {
    final am = (draft.amountPaise / 100).toStringAsFixed(2);
    final pn = Uri.encodeComponent(draft.payeeName);
    final tn = Uri.encodeComponent(draft.note);
    return 'upi://pay?pa=${draft.vpa}&pn=$pn&am=$am&cu=INR&tn=$tn';
  }

  static PaymentRail select(NetworkInfo info) {
    if (info.platform != 'android') return PaymentRail.upiIntent;
    if (info.recommendedRail == 'ussd' && info.ussdSupported) return PaymentRail.ussd;
    return PaymentRail.ivr;
  }
}
