// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navPay => 'Pay';

  @override
  String get navHistory => 'History';

  @override
  String get navProfile => 'Profile';

  @override
  String get homeScan => 'Scan';

  @override
  String get homeSend => 'Send';

  @override
  String get homeSplit => 'Split';

  @override
  String get homeMyCard => 'My Card';

  @override
  String get homeInviteFriends => 'Invite Friends';

  @override
  String get amountTitle => 'Enter amount';

  @override
  String amountPaying(String who) {
    return 'Paying $who';
  }

  @override
  String get amountNoteOptional => 'NOTE (OPTIONAL)';

  @override
  String get amountSpendingOn => 'SPENDING ON';

  @override
  String get amountConfirm => 'CONFIRM';

  @override
  String get amountPay => 'PAY';

  @override
  String amountPayWithTotal(String total) {
    return 'PAY $total';
  }

  @override
  String get paymentSuccess => 'Payment Successful';

  @override
  String get paymentFailed => 'Payment Failed';

  @override
  String get paymentPending => 'Payment Pending';

  @override
  String get paymentPendingHint =>
      'Check SMS from your bank, or History in a minute.';

  @override
  String get paymentFailedHint =>
      'Nothing was taken in Zep Pay. Try again when the dialer session is ready.';

  @override
  String get walkthroughSkip => 'Skip';

  @override
  String get walkthroughNext => 'Next';

  @override
  String get walkthroughGetStarted => 'Get Started';

  @override
  String get walkthroughWelcomeTitle => 'Welcome to Zep Pay';

  @override
  String get walkthroughWelcomeBody => 'Pay anywhere, even offline.';

  @override
  String get walkthroughNfcTitle => 'Tap with Zep Card';

  @override
  String get walkthroughNfcBody =>
      'Use NFC to pay or identify yourself on our closed-loop network.';

  @override
  String get walkthroughOfflineTitle => 'Zero internet needed';

  @override
  String get walkthroughOfflineBody =>
      'Payments ride the same *99# / 123PAY rail when data drops.';

  @override
  String get walkthroughShopTitle => 'Shop & ZepCoins';

  @override
  String get walkthroughShopBody =>
      'Earn coins on every payment and redeem demo partner offers.';
}
