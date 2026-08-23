import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Lightweight UX memory (not secrets): last phone, default spend chip.
class UxPrefs {
  static const _phone = 'ux_last_phone';
  static const _spend = 'ux_default_spend';
  static const _ussdAuto = 'ux_ussd_auto_mode';
  static const _themeMode = 'ux_theme_mode';
  static const _hasSeenOnboarding = 'has_seen_onboarding';
  static const _localeCode = 'ux_locale_code';
  static const _largerText = 'ux_larger_text';
  static const _highContrast = 'ux_high_contrast';

  static Future<ThemeMode> themeMode() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_themeMode);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final p = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await p.setString(_themeMode, value);
  }

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

  static Future<bool> hasSeenOnboarding() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_hasSeenOnboarding) ?? false;
  }

  static Future<void> setHasSeenOnboarding(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_hasSeenOnboarding, value);
  }

  static Future<String> localeCode() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_localeCode) ?? 'en';
  }

  static Future<void> saveLocaleCode(String code) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_localeCode, code);
  }

  static Future<bool> largerText() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_largerText) ?? false;
  }

  static Future<void> saveLargerText(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_largerText, value);
  }

  static Future<bool> highContrast() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_highContrast) ?? false;
  }

  static Future<void> saveHighContrast(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_highContrast, value);
  }
}
