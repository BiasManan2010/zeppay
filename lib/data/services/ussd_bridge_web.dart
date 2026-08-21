/// USSD auto mode is Android-only.
class UssdBridge {
  UssdBridge._();

  static Future<void> init({
    void Function(String prompt, bool isPinStep)? onMessage,
    void Function()? onEnded,
  }) async {}

  static Future<bool> isAccessibilityEnabled() async => false;

  static Future<bool> canDrawOverlays() async => false;

  static Future<bool> isAutoReady() async => false;

  static Future<void> openAccessibilitySettings() async {}

  static Future<void> openOverlaySettings() async {}

  static Future<void> startSession() async {}

  static Future<void> endSession() async {}

  static Future<void> submitReply(String reply) async {}

  static Future<void> showOverlay({
    required String prompt,
    required bool isPinStep,
  }) async {}
}
