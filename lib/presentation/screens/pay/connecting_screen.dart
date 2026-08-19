import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../data/services/payment_status_detector.dart';
import '../../../data/services/providers.dart';
import '../../../data/services/payment_session.dart';
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
  String? _txnId;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 280), _run);
  }

  Future<void> _finish(TxStatus status) async {
    await applyPaymentResult(ref, status);
    if (!mounted) return;
    context.go(routeForTxStatus(status));
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
      final refCode = AppStore.payRef();

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
        refCode: refCode,
      );
      await ref.read(appStoreProvider.notifier).logTransaction(tx);
      ref.read(pendingTxIdProvider.notifier).state = tx.id;
      ref.read(paymentSessionProvider.notifier).begin(tx.id);
      setState(() => _txnId = refCode);

      if (isWebApp) {
        await Clipboard.setData(ClipboardData(text: draft.vpa));
        setState(() {
          _label = 'Opening Phone…';
          _detail =
              'UPI ID copied. *99*1*3 is send-to-UPI. Paste if asked, then PIN.\nTxn $refCode';
        });
        await audit.dialOpened(tx.id, dial);
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tel.dial(dial);
        setState(() {
          _label = 'Checking payment…';
          _detail = 'Waiting until you return from Phone.';
        });
        final away = await waitForDialerReturn();
        final status = detectPaymentStatus(away);
        ref.read(paymentSessionProvider.notifier).recordReturn(away);
        await audit.dialReturned(tx.id, away, status);
        if (!mounted) return;
        setState(() {
          _label = 'Txn $refCode';
          _detail = suggestionLabel(status, away);
        });
        await Future<void>.delayed(const Duration(milliseconds: 700));
        await _finish(status);
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
                'Could not open a UPI app. Install GPay or PhonePe, then retry.';
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
      final status = detectPaymentStatus(away);
      ref.read(paymentSessionProvider.notifier).recordReturn(away);
      await audit.dialReturned(tx.id, away, status);
      await _finish(status);
    } catch (e) {
      setState(() => _error = e.toString());
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (mounted && ref.read(pendingTxIdProvider) != null) {
        await _finish(TxStatus.failed);
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
                          ? 'Preparing *99*1*3…'
                          : _detail,
                      key: ValueKey(_detail),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  if (_txnId != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _txnId!,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.hero,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ],
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
