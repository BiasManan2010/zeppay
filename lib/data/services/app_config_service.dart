import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_service.dart';

const donationsEnabledKey = 'donations_enabled';

/// Cached donations toggle — refreshed once per app open (fail closed).
final donationsEnabledProvider = StateProvider<bool>((_) => false);

class AppConfigService {
  AppConfigService(this._prefs);

  final SharedPreferences _prefs;

  static const cacheKey = 'app_config_donations_enabled';

  bool get cachedDonationsEnabled => _prefs.getBool(cacheKey) ?? false;

  /// Fetch from Supabase when configured; otherwise use cache. Fail closed.
  Future<bool> refreshDonationsEnabled() async {
    var enabled = false;
    if (SupabaseService.instance.isReady) {
      try {
        final row = await SupabaseService.instance.client
            .from('app_config')
            .select('value')
            .eq('key', donationsEnabledKey)
            .maybeSingle();
        enabled = row?['value'] == 'true';
        await _prefs.setBool(cacheKey, enabled);
      } catch (e) {
        debugPrint('app_config fetch failed: $e');
        enabled = cachedDonationsEnabled;
      }
    } else {
      enabled = cachedDonationsEnabled;
    }
    return enabled;
  }
}

final appConfigServiceProvider = Provider<AppConfigService>((ref) {
  throw UnimplementedError('Override in main after SharedPreferences init');
});

Future<void> refreshAppConfigOnce(WidgetRef ref) async {
  final service = ref.read(appConfigServiceProvider);
  final enabled = await service.refreshDonationsEnabled();
  ref.read(donationsEnabledProvider.notifier).state = enabled;
}
