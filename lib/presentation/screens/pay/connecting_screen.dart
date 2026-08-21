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
import '../../../data/local/ux_prefs.dart';
import '../../../data/services/dial_return.dart';
import '../../../data/services/network_info.dart';
import '../../../data/services/payment_session.dart';
import '../../../data/services/payment_tracker.dart';
import '../../../data/services/providers.dart';
import '../../../data/services/rail_engine.dart';
import '../../../data/services/security_audit.dart';
import '../../../data/services/ussd_bridge.dart';
import '../../../presentation/widgets/payment_track_card.dart';

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

  Future<void> _runOfflineDial({
    required PaymentDraft draft,
    required String dial,
    required String txId,
    required String refCode,
    required SecurityAudit audit,
    required dynamic tel,
    required NetworkInfo info,
  }) async {
    final session = ref.read(paymentSessionProvider.notifier);
    var autoActive = false;
    if (isAndroidDevice && !isWebApp) {
      final autoMode = await UxPrefs.ussdAutoMode();
      if (autoMode && (info.ussdSupported || info.isJio)) {
        final ready = await UssdBridge.isAutoReady();
        if (ready) {
          await UssdBridge.init();
          await UssdBridge.startSession();
          autoActive = true;
        }
      }
    }
    try {
      await Clipboard.setData(ClipboardData(text: draft.vpa));
      await session.markUpiCopied();
      if (!mounted) return;
      setState(() {
        _label = autoActive ? 'Auto USSD…' : 'Opening Phone…';
        _detail = autoActive
            ? (info.isJio
                ? 'Zep Pay overlay guides 123PAY IVR on Jio.\nTxn $refCode'
                : 'Zep Pay overlay collects your PIN — not the carrier popup.\nTxn $refCode')
            : info.isJio
                ? '123PAY IVR opens for Jio. Follow voice prompts, then PIN.\nTxn $refCode'
                : 'UPI ID copied. *99*1*3 is send-to-UPI. Paste if asked, then PIN.\nTxn $refCode';
      });
      await audit.dialOpened(txId, dial);
      await session.markDialOpened(dial);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await tel.dial(dial);
      await session.markInPhone();
      if (!mounted) return;
      setState(() {
        _label = 'Tracking payment…';
        _detail = autoActive
            ? 'Follow the Zep Pay overlay for each USSD step.'
            : 'Complete USSD in Phone, then return here to confirm.';
      });
      try {
        final report = await waitForDialerReturn();
        await session.recordDialSession(report);
        await audit.dialReturned(
          txId,
          report.longestStint,
          null,
        );
      } catch (_) {
        await session.markAwaitingConfirm();
      }
      if (!mounted) return;
      context.go('/outcome');
    } finally {
      if (autoActive) {
        await UssdBridge.endSession();
      }
    }
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
      final rail = isIosWeb ? PaymentRail.upiIntent : RailEngine.select(info);
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
      await ref.read(paymentSessionProvider.notifier).begin(
            txId: tx.id,
            refCode: refCode,
            vpa: draft.vpa,
            amountPaise: draft.amountPaise,
          );
      setState(() => _txnId = refCode);

      if (rail == PaymentRail.upiIntent) {
        setState(() {
          _label = 'Opening your UPI app';
          _detail = info.isJio
              ? 'Jio: pay in GPay / PhonePe with your UPI PIN.\nTxn $refCode'
              : 'Complete payment in your UPI app.\nTxn $refCode';
        });
        await Clipboard.setData(ClipboardData(text: draft.vpa));
        await ref.read(paymentSessionProvider.notifier).markUpiCopied();
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
        await ref.read(paymentSessionProvider.notifier).markAwaitingConfirm();
        if (mounted) context.go('/outcome');
        return;
      }

      await _runOfflineDial(
        draft: draft,
        dial: dial,
        txId: tx.id,
        refCode: refCode,
        audit: audit,
        tel: tel,
        info: info,
      );
    } catch (e) {
      setState(() => _error = e.toString());
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (mounted && ref.read(pendingTxIdProvider) != null) {
        await ref.read(paymentSessionProvider.notifier).markAwaitingConfirm();
        context.go('/outcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(paymentSessionProvider).value?.track;
    final steps = track == null ? const <PaymentTrackStep>[] : trackSteps(track);

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
                      _detail.isEmpty ? 'Preparing *99*1*3…' : _detail,
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
                  if (steps.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    PaymentTrackCard(steps: steps),
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
