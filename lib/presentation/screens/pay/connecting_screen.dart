import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/motion/app_motion.dart';
import '../../../core/platform.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/chrome.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/models.dart';
import '../../../data/services/dial_return.dart';
import '../../../data/services/providers.dart';
import '../../../data/services/rail_engine.dart';
import '../../../data/services/security_audit.dart';

class ConnectingScreen extends ConsumerStatefulWidget {
  const ConnectingScreen({super.key});

  @override
  ConsumerState<ConnectingScreen> createState() => _ConnectingScreenState();
}

class _ConnectingScreenState extends ConsumerState<ConnectingScreen> {
  String _label = 'Selecting rail…';
  String _detail = '';
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
    final audit = await ref.read(securityAuditProvider.future);
    try {
      await tel.requestPermissions();
      final info = await tel.networkInfo();
      final rail = RailEngine.select(info);
      ref.read(lastRailProvider.notifier).state = rail;
      final dial = RailEngine.dialFor(rail, draft);

      final tx = TxRecord(
        id: AppStore.id(),
        vpa: draft.vpa,
        amountPaise: draft.amountPaise,
        status: TxStatus.pending,
        createdAt: DateTime.now(),
        payeeName: draft.payeeName,
        note: draft.note,
        category: draft.category,
        rail: rail,
        offline: rail != PaymentRail.upiIntent,
        refCode: AppStore.payRef(),
      );
      await ref.read(appStoreProvider.notifier).logTransaction(tx);
      ref.read(pendingTxIdProvider.notifier).state = tx.id;
      ref.read(paymentSessionProvider.notifier).begin(tx.id);

      if (isWebApp) {
        setState(() {
          if (rail == PaymentRail.ivr) {
            _label = 'Calling 123PAY…';
            _detail = RailEngine.ivrScript(draft);
          } else {
            _label = 'Dialing *99#…';
            _detail = 'Phone opens with the USSD string. Enter UPI PIN in the dialer.';
          }
        });
        await audit.dialOpened(tx.id, dial);
        await Future<void>.delayed(const Duration(milliseconds: 450));
        await tel.dial(dial);
        final away = await waitForDialerReturn();
        ref.read(paymentSessionProvider.notifier).recordReturn(away);
        final suggestion = ref.read(paymentSessionProvider).suggestion;
        await audit.dialReturned(tx.id, away, suggestion);
        if (mounted) context.go('/outcome');
        return;
      }

      if (!isAndroidDevice) {
        setState(() {
          _label = 'Opening your UPI app';
          _detail = RailEngine.upiUri(draft);
        });
        await Future<void>.delayed(const Duration(milliseconds: 400));
        final uri = Uri.parse(RailEngine.upiUri(draft));
        var opened = false;
        try {
          opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          opened = false;
        }
        if (!opened && mounted) {
          setState(() {
            _error =
                'Could not open a UPI app. Install GPay or PhonePe on this iPhone, then retry.';
          });
          return;
        }
        if (mounted) context.go('/outcome');
        return;
      }

      setState(() {
        if (rail == PaymentRail.ivr) {
          _label = 'Connecting via 123PAY…';
          _detail = RailEngine.ivrScript(draft);
        } else {
          _label = 'Connecting via *99#…';
          _detail = dial;
        }
      });
      await Future<void>.delayed(const Duration(milliseconds: 900));
      final dialStart = DateTime.now();
      await audit.dialOpened(tx.id, dial);
      await tel.dial(dial);
      await tel.waitForCallEnd();
      final away = DateTime.now().difference(dialStart);
      ref.read(paymentSessionProvider.notifier).recordReturn(away);
      await audit.dialReturned(
        tx.id,
        away,
        ref.read(paymentSessionProvider).suggestion,
      );
      if (mounted) context.go('/outcome');
    } catch (e) {
      setState(() => _error = e.toString());
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (mounted && ref.read(pendingTxIdProvider) != null) {
        context.go('/outcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGlow),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SignalArcs(size: 160),
                  const SizedBox(height: 28),
                  SoftSwitcher(
                    child: Text(
                      _label,
                      key: ValueKey(_label),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SoftSwitcher(
                    child: Text(
                      _detail.isEmpty
                          ? (isWebApp
                              ? 'Safari hands off to Phone — *99# or 123PAY.'
                              : isIosDevice
                                  ? 'Offline USSD/IVR is Android-only. Using online UPI instead.'
                                  : 'Enter your UPI PIN when the bank asks.')
                          : _detail,
                      key: ValueKey(_detail),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                    const SizedBox(height: 12),
                    GlowButton(
                      label: 'BACK HOME',
                      onTap: () => context.go('/home'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
