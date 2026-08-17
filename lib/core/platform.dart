import 'package:flutter/foundation.dart';

bool get isAndroidDevice =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

bool get isIosDevice =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

bool get isWebApp => kIsWeb;

/// Safari / GitHub Pages PWA — no USSD, dialer, or device address book.
bool get supportsOfflineRails => isAndroidDevice;

bool get supportsDeviceContacts => !kIsWeb;
