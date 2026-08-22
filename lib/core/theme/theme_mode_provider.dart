import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/ux_prefs.dart';

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    Future.microtask(_hydrate);
    return ThemeMode.dark;
  }

  Future<void> _hydrate() async {
    state = await UxPrefs.themeMode();
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await UxPrefs.saveThemeMode(mode);
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setMode(next);
  }
}
