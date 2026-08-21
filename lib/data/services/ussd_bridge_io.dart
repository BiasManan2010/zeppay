import 'package:flutter/services.dart';

/// Android USSD auto mode via Accessibility + overlay. Manual mode is default.
class UssdBridge {
  UssdBridge._();

  static const _channel = MethodChannel('in.zeppay/ussd');
  static void Function(String prompt, bool isPinStep)? _onMessage;
  static void Function()? _onEnded;

  static Future<void> init({
    void Function(String prompt, bool isPinStep)? onMessage,
    void Function()? onEnded,
  }) async {
    _onMessage = onMessage;
    _onEnded = onEnded;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'ussdMessage':
          final args = call.arguments as Map?;
          final text = args?['text'] as String? ?? '';
          final pin = args?['isPinStep'] as bool? ?? false;
          _onMessage?.call(text, pin);
        case 'ussdEnded':
          _onEnded?.call();
      }
    });
  }

  static Future<bool> isAccessibilityEnabled() async {
    final v = await _channel.invokeMethod<bool>('isAccessibilityEnabled');
    return v ?? false;
  }

  static Future<bool> canDrawOverlays() async {
    final v = await _channel.invokeMethod<bool>('canDrawOverlays');
    return v ?? false;
  }

  static Future<bool> isAutoReady() async {
    return await isAccessibilityEnabled() && await canDrawOverlays();
  }

  static Future<void> openAccessibilitySettings() =>
      _channel.invokeMethod<void>('openAccessibilitySettings');

  static Future<void> openOverlaySettings() =>
      _channel.invokeMethod<void>('openOverlaySettings');

  static Future<void> startSession() => _channel.invokeMethod<void>('startSession');

  static Future<void> endSession() => _channel.invokeMethod<void>('endSession');

  static Future<void> submitReply(String reply) async {
    await _channel.invokeMethod<void>('submitReply', {'reply': reply});
  }

  static Future<void> showOverlay({
    required String prompt,
    required bool isPinStep,
  }) =>
      _channel.invokeMethod<void>('showOverlay', {
        'prompt': prompt,
        'isPinStep': isPinStep,
      });
}
