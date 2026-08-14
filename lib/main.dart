import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/local/app_store.dart';
import 'data/services/autopay_scheduler.dart';
import 'data/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(const ProviderScope(child: ZepPayApp()));
}

class ZepPayApp extends ConsumerStatefulWidget {
  const ZepPayApp({super.key});

  @override
  ConsumerState<ZepPayApp> createState() => _ZepPayAppState();
}

class _ZepPayAppState extends ConsumerState<ZepPayApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(autopaySchedulerProvider).tick();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appStoreProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Zeppay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
