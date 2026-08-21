// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'app_urls.dart';

void redirectIosToPaySite() {
  html.window.location.replace(AppUrls.iosWebSite);
}
