// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

bool get platformIsIosWeb {
  final ua = html.window.navigator.userAgent.toLowerCase();
  return ua.contains('iphone') ||
      ua.contains('ipad') ||
      ua.contains('ipod');
}

bool get platformIsAndroidWeb {
  final ua = html.window.navigator.userAgent.toLowerCase();
  return ua.contains('android');
}
