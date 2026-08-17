import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Waits until Safari returns from the Phone dialer (Page Visibility API).
Future<Duration> waitForDialerReturn({
  Duration timeout = const Duration(minutes: 5),
}) async {
  final completer = Completer<Duration>();
  Timer? timer;
  DateTime? hiddenAt;

  void onChange(html.Event _) {
    if (html.document.visibilityState == 'hidden') {
      hiddenAt ??= DateTime.now();
      return;
    }
    if (html.document.visibilityState == 'visible' && hiddenAt != null) {
      final away = DateTime.now().difference(hiddenAt!);
      timer?.cancel();
      html.document.removeEventListener('visibilitychange', onChange);
      if (!completer.isCompleted) completer.complete(away);
    }
  }

  html.document.addEventListener('visibilitychange', onChange);
  timer = Timer(timeout, () {
    html.document.removeEventListener('visibilitychange', onChange);
    if (!completer.isCompleted) {
      completer.completeError(TimeoutException('Dial session timed out'));
    }
  });

  return completer.future;
}
