import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/ux_prefs.dart';

/// Device-local accessibility preferences (not synced to Supabase).
final largerTextProvider = NotifierProvider<LargerTextController, bool>(
  LargerTextController.new,
);

class LargerTextController extends Notifier<bool> {
  @override
  bool build() {
    Future.microtask(_hydrate);
    return false;
  }

  Future<void> _hydrate() async {
    state = await UxPrefs.largerText();
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    await UxPrefs.saveLargerText(value);
  }
}

final highContrastProvider = NotifierProvider<HighContrastController, bool>(
  HighContrastController.new,
);

class HighContrastController extends Notifier<bool> {
  @override
  bool build() {
    Future.microtask(_hydrate);
    return false;
  }

  Future<void> _hydrate() async {
    state = await UxPrefs.highContrast();
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    await UxPrefs.saveHighContrast(value);
  }
}

/// Text scale multiplier when "Larger text" is enabled.
const largerTextScaleFactor = 1.22;
