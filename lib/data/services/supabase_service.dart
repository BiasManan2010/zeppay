import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shared Supabase client for census OTP (backend) and semiconductor inventory.
class SupabaseService {
  SupabaseService._();
  static final instance = SupabaseService._();

  static const compiledUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const compiledAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const urlPrefsKey = 'supabase_url';
  static const anonKeyPrefsKey = 'supabase_anon_key';

  var _ready = false;

  bool get isReady => _ready && Supabase.instance.isInitialized;

  SupabaseClient get client => Supabase.instance.client;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final url = (prefs.getString(urlPrefsKey) ?? compiledUrl).trim();
    final anon = (prefs.getString(anonKeyPrefsKey) ?? compiledAnonKey).trim();
    if (url.isEmpty || anon.isEmpty) {
      debugPrint('Supabase: URL/anon key not set — inventory uses cloud when configured.');
      return;
    }
    if (!Supabase.instance.isInitialized) {
      await Supabase.initialize(url: url, publishableKey: anon);
    }
    _ready = true;
  }

  Future<void> saveConfig({required String url, required String anonKey}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(urlPrefsKey, url.trim());
    await prefs.setString(anonKeyPrefsKey, anonKey.trim());
  }

  Future<({String url, String anonKey})> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      url: (prefs.getString(urlPrefsKey) ?? compiledUrl).trim(),
      anonKey: (prefs.getString(anonKeyPrefsKey) ?? compiledAnonKey).trim(),
    );
  }

  void requireReady() {
    if (!isReady) {
      throw StateError(
        'Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY '
        'in Settings, or pass --dart-define values at build time.',
      );
    }
  }
}
