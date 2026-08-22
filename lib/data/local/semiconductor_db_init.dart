import 'package:flutter/foundation.dart';

import '../local/semiconductor_database.dart';

/// Opens the semiconductor DB on app start (mobile/desktop only).
Future<void> initSemiconductorDatabase() async {
  if (kIsWeb) return;
  try {
    await SemiconductorDatabase.instance.database;
  } catch (e) {
    debugPrint('semiconductor db init failed: $e');
  }
}
