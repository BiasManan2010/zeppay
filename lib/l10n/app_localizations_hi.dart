// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get navHome => 'होम';

  @override
  String get navPay => 'भुगतान';

  @override
  String get navHistory => 'इतिहास';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get homeScan => 'स्कैन';

  @override
  String get homeSend => 'भेजें';

  @override
  String get homeSplit => 'बाँटें';

  @override
  String get homeMyCard => 'मेरा कार्ड';

  @override
  String get homeInviteFriends => 'मित्रों को आमंत्रित करें';

  @override
  String get amountTitle => 'राशि दर्ज करें';

  @override
  String amountPaying(String who) {
    return '$who को भुगतान';
  }

  @override
  String get amountNoteOptional => 'नोट (वैकल्पिक)';

  @override
  String get amountSpendingOn => 'खर्च श्रेणी';

  @override
  String get amountConfirm => 'पुष्टि करें';

  @override
  String get amountPay => 'भुगतान';

  @override
  String amountPayWithTotal(String total) {
    return '$total भुगतान';
  }

  @override
  String get paymentSuccess => 'भुगतान सफल';

  @override
  String get paymentFailed => 'भुगतान विफल';

  @override
  String get paymentPending => 'भुगतान लंबित';

  @override
  String get paymentPendingHint =>
      'बैंक के SMS की जाँच करें, या थोड़ी देर में इतिहास देखें।';

  @override
  String get paymentFailedHint =>
      'Zep Pay में कोई राशि नहीं ली गई। डायलर तैयार होने पर फिर कोशिश करें।';

  @override
  String get walkthroughSkip => 'छोड़ें';

  @override
  String get walkthroughNext => 'आगे';

  @override
  String get walkthroughGetStarted => 'शुरू करें';

  @override
  String get walkthroughWelcomeTitle => 'Zep Pay में आपका स्वागत है';

  @override
  String get walkthroughWelcomeBody => 'कहीं भी भुगतान करें, ऑफ़लाइन भी।';

  @override
  String get walkthroughNfcTitle => 'Zep Card से टैप करें';

  @override
  String get walkthroughNfcBody =>
      'हमारे नेटवर्क पर भुगतान या पहचान के लिए NFC का उपयोग करें।';

  @override
  String get walkthroughOfflineTitle => 'इंटरनेट की ज़रूरत नहीं';

  @override
  String get walkthroughOfflineBody =>
      'डेटा गिरने पर भी *99# / 123PAY रेल से भुगतान होता है।';

  @override
  String get walkthroughShopTitle => 'शॉप और ZepCoins';

  @override
  String get walkthroughShopBody =>
      'हर भुगतान पर सिक्के कमाएँ और डेमो ऑफ़र रिडीम करें।';
}
