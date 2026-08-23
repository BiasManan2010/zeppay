import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/ux_prefs.dart';

final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    Future.microtask(_hydrate);
    return const Locale('en');
  }

  Future<void> _hydrate() async {
    final code = await UxPrefs.localeCode();
    state = Locale(code);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await UxPrefs.saveLocaleCode(locale.languageCode);
  }

  Future<void> toggleEnHi() async {
    final next = state.languageCode == 'hi' ? 'en' : 'hi';
    await setLocale(Locale(next));
  }
}
