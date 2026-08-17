import 'package:flutter/foundation.dart';

bool get isAndroidDevice =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

bool get isIosDevice =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

bool get isWebApp => kIsWeb;
