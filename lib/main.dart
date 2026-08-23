import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/accessibility/accessibility_provider.dart';
import 'core/locale/locale_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'data/local/app_store.dart';
import 'data/services/autopay_scheduler.dart';
import 'data/services/nfc_deep_link.dart';
import 'data/services/notification_service.dart';
import 'data/services/referral_flow.dart';
import 'data/services/supabase_service.dart';
import 'l10n/app_localizations.dart';

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
  runApp(const ProviderScope(child: ZepPayApp()));
}

class ZepPayApp extends ConsumerStatefulWidget {
  const ZepPayApp({super.key});

  @override
  ConsumerState<ZepPayApp> createState() => _ZepPayAppState();
}

class _ZepPayAppState extends ConsumerState<ZepPayApp> {
  NfcDeepLinkListener? _deepLinks;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(autopaySchedulerProvider).tick();
      final router = ref.read(routerProvider);
      _deepLinks = NfcDeepLinkListener(router, ref.read(appLinksProvider));
      await _deepLinks!.init();
      await syncReferralRewards(ref);
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
    final locale = ref.watch(localeProvider);
    final largerText = ref.watch(largerTextProvider);
    final highContrast = ref.watch(highContrastProvider);

    return MaterialApp.router(
      title: 'Zeppay',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(highContrast: highContrast),
      darkTheme: AppTheme.dark(highContrast: highContrast),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        final scale = largerText ? largerTextScaleFactor : 1.0;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
