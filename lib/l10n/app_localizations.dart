import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi')
  ];

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navPay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get navPay;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @homeScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get homeScan;

  /// No description provided for @homeSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get homeSend;

  /// No description provided for @homeSplit.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get homeSplit;

  /// No description provided for @homeMyCard.
  ///
  /// In en, this message translates to:
  /// **'My Card'**
  String get homeMyCard;

  /// No description provided for @homeInviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get homeInviteFriends;

  /// No description provided for @amountTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get amountTitle;

  /// No description provided for @amountPaying.
  ///
  /// In en, this message translates to:
  /// **'Paying {who}'**
  String amountPaying(String who);

  /// No description provided for @amountNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'NOTE (OPTIONAL)'**
  String get amountNoteOptional;

  /// No description provided for @amountSpendingOn.
  ///
  /// In en, this message translates to:
  /// **'SPENDING ON'**
  String get amountSpendingOn;

  /// No description provided for @amountConfirm.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM'**
  String get amountConfirm;

  /// No description provided for @amountPay.
  ///
  /// In en, this message translates to:
  /// **'PAY'**
  String get amountPay;

  /// No description provided for @amountPayWithTotal.
  ///
  /// In en, this message translates to:
  /// **'PAY {total}'**
  String amountPayWithTotal(String total);

  /// No description provided for @paymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful'**
  String get paymentSuccess;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed'**
  String get paymentFailed;

  /// No description provided for @paymentPending.
  ///
  /// In en, this message translates to:
  /// **'Payment Pending'**
  String get paymentPending;

  /// No description provided for @paymentPendingHint.
  ///
  /// In en, this message translates to:
  /// **'Check SMS from your bank, or History in a minute.'**
  String get paymentPendingHint;

  /// No description provided for @paymentFailedHint.
  ///
  /// In en, this message translates to:
  /// **'Nothing was taken in Zep Pay. Try again when the dialer session is ready.'**
  String get paymentFailedHint;

  /// No description provided for @walkthroughSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get walkthroughSkip;

  /// No description provided for @walkthroughNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get walkthroughNext;

  /// No description provided for @walkthroughGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get walkthroughGetStarted;

  /// No description provided for @walkthroughWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Zep Pay'**
  String get walkthroughWelcomeTitle;

  /// No description provided for @walkthroughWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Pay anywhere, even offline.'**
  String get walkthroughWelcomeBody;

  /// No description provided for @walkthroughNfcTitle.
  ///
  /// In en, this message translates to:
  /// **'Tap with Zep Card'**
  String get walkthroughNfcTitle;

  /// No description provided for @walkthroughNfcBody.
  ///
  /// In en, this message translates to:
  /// **'Use NFC to pay or identify yourself on our closed-loop network.'**
  String get walkthroughNfcBody;

  /// No description provided for @walkthroughOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Zero internet needed'**
  String get walkthroughOfflineTitle;

  /// No description provided for @walkthroughOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Payments ride the same *99# / 123PAY rail when data drops.'**
  String get walkthroughOfflineBody;

  /// No description provided for @walkthroughShopTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop & ZepCoins'**
  String get walkthroughShopTitle;

  /// No description provided for @walkthroughShopBody.
  ///
  /// In en, this message translates to:
  /// **'Earn coins on every payment and redeem demo partner offers.'**
  String get walkthroughShopBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
