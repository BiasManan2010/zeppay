import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../data/models/models.dart';
import '../../../data/services/providers.dart';
import '../../../data/services/rail_engine.dart';

class ConnectingScreen extends ConsumerStatefulWidget {
  const ConnectingScreen({super.key});

  @override
  ConsumerState<ConnectingScreen> createState() => _ConnectingScreenState();
}

class _ConnectingScreenState extends ConsumerState<ConnectingScreen> {
  String _label = 'Selecting rail…';
  String? _error;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 400), _run);
  }

  Future<void> _run() async {
    final draft = ref.read(paymentDraftProvider);
    if (draft == null) {
      if (mounted) context.go('/home');
      return;
    }
    final tel = ref.read(telephonyServiceProvider);
    try {
      await tel.requestPermissions();
      final info = await tel.networkInfo();
      final rail = RailEngine.select(info);
      ref.read(lastRailProvider.notifier).state = rail;
      final dial = RailEngine.dialFor(rail, draft);

      if (!Platform.isAndroid) {
        setState(() => _label = 'Opening UPI (iOS fallback)');
        await Future<void>.delayed(const Duration(milliseconds: 600));
        final uri = Uri.parse(RailEngine.upiUri(draft));
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        if (mounted) context.go('/confirm');
        return;
      }

      setState(() {
        _label = rail == PaymentRail.ivr
            ? 'Connecting via 123PAY…'
            : 'Connecting via *99#…';
      });
      await Future<void>.delayed(const Duration(milliseconds: 900));
      await tel.dial(dial);
      await tel.waitForCallEnd();
      if (mounted) context.go('/confirm');
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGlow),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SignalArcs(size: 160),
                const SizedBox(height: 28),
                Text(_label, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  Platform.isIOS
                      ? 'Offline USSD/IVR is Android-only. Using online UPI instead.'
                      : 'Enter your UPI PIN when the dialer asks. We pull you back the instant the call ends.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: AppColors.danger)),
                  const SizedBox(height: 12),
                  HapticScale(
                    onTap: () => context.go('/home'),
                    child: const Text('BACK HOME'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
