import 'package:flutter/foundation.dart';

import 'platform_detect.dart';

bool get isAndroidDevice =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

bool get isIosDevice =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

bool get isWebApp => kIsWeb;

/// iPhone / iPad Safari or home-screen PWA.
bool get isIosWeb => isWebApp && platformIsIosWeb;

/// Android mobile browser (not the native APK).
bool get isAndroidWeb => isWebApp && platformIsAndroidWeb;

/// Safari / GitHub Pages PWA — no USSD, dialer, or device address book.
bool get supportsOfflineRails => isAndroidDevice;

bool get supportsDeviceContacts => !kIsWeb;

/// *99# USSD only works from an Android phone dialer, not iOS.
bool get supportsUssdDial => isAndroidDevice || isAndroidWeb;
