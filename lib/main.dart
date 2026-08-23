import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'data/local/app_store.dart';
import 'data/services/app_config_service.dart';
import 'data/services/autopay_scheduler.dart';
import 'data/services/nfc_deep_link.dart';
import 'data/services/notification_service.dart';
import 'data/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Zep Pay: $error\n$stack');
    return true;
  };
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('notifications init failed: $e');
  }
  try {
    await SupabaseService.instance.init();
  } catch (e) {
    debugPrint('supabase init failed: $e');
  }
  final prefs = await SharedPreferences.getInstance();
  final configService = AppConfigService(prefs);
  runApp(
    ProviderScope(
      overrides: [
        appConfigServiceProvider.overrideWithValue(configService),
        donationsEnabledProvider.overrideWith(
          (ref) => configService.cachedDonationsEnabled,
        ),
      ],
      child: const ZepPayApp(),
    ),
  );
}

class ZepPayApp extends ConsumerStatefulWidget {
  const ZepPayApp({super.key});

  @override
  ConsumerState<ZepPayApp> createState() => _ZepPayAppState();
}

class _ZepPayAppState extends ConsumerState<ZepPayApp> {
  NfcDeepLinkListener? _deepLinks;
  var _configLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(autopaySchedulerProvider).tick();
      final router = ref.read(routerProvider);
      _deepLinks = NfcDeepLinkListener(router, ref.read(appLinksProvider));
      await _deepLinks!.init();
      if (!_configLoaded) {
        _configLoaded = true;
        final enabled =
            await ref.read(appConfigServiceProvider).refreshDonationsEnabled();
        ref.read(donationsEnabledProvider.notifier).state = enabled;
      }
    });
  }

  @override
  void dispose() {
    _deepLinks?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appStoreProvider);
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Zeppay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
