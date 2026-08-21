import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight UX memory (not secrets): last phone, default spend chip.
class UxPrefs {
  static const _phone = 'ux_last_phone';
  static const _spend = 'ux_default_spend';
  static const _ussdAuto = 'ux_ussd_auto_mode';

  static Future<bool> ussdAutoMode() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_ussdAuto) ?? false;
  }

  static Future<void> saveUssdAutoMode(bool enabled) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_ussdAuto, enabled);
  }

  static Future<String> lastPhone() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_phone) ?? '';
  }

  static Future<void> savePhone(String phone) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_phone, phone);
  }

  static Future<String> defaultSpend() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_spend) ?? 'food';
  }

  static Future<void> saveSpend(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_spend, id);
  }
}
