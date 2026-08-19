import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'dial_session.dart';

/// Waits until Safari returns from the Phone dialer (Page Visibility API).
Future<DialSessionReport> waitForDialerReturn({
  Duration timeout = const Duration(minutes: 5),
}) async {
  final completer = Completer<DialSessionReport>();
  Timer? timer;
  DateTime? stintStart;
  var longest = Duration.zero;
  var total = Duration.zero;
  var stints = 0;
  DateTime? firstLeft;
  DateTime? lastReturn;

  void onChange(html.Event _) {
    if (html.document.visibilityState == 'hidden') {
      stintStart ??= DateTime.now();
      firstLeft ??= stintStart;
      return;
    }
    if (html.document.visibilityState != 'visible' || stintStart == null) {
      return;
    }
    final stint = DateTime.now().difference(stintStart!);
    stintStart = null;
    total += stint;
    stints++;
    if (stint > longest) longest = stint;
    lastReturn = DateTime.now();
    timer?.cancel();
    html.document.removeEventListener('visibilitychange', onChange);
    if (!completer.isCompleted) {
      completer.complete(
        DialSessionReport(
          longestStint: longest,
          totalHidden: total,
          stintCount: stints,
          leftAt: firstLeft,
          returnedAt: lastReturn,
        ),
      );
    }
  }

  html.document.addEventListener('visibilitychange', onChange);
  timer = Timer(timeout, () {
    html.document.removeEventListener('visibilitychange', onChange);
    if (!completer.isCompleted) {
      completer.complete(
        DialSessionReport(
          longestStint: longest,
          totalHidden: total,
          stintCount: stints,
          leftAt: firstLeft,
          returnedAt: lastReturn,
          timedOut: true,
        ),
      );
    }
  });

  return completer.future;
}
