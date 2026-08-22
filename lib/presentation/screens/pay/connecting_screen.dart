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
import '../../../data/services/dial_telemetry.dart';
import '../../../data/services/network_info.dart';
import '../../../data/services/payment_session.dart';
import '../../../data/services/payment_tracker.dart';
import '../../../data/services/providers.dart';
import '../../../data/services/rail_engine.dart';
import '../../../data/services/security_audit.dart';
import '../../../data/services/ussd_bridge.dart';
import '../../../presentation/widgets/payment_track_card.dart';

enum _ConnectPhase { selecting, amountSent, enterPin, tracking, error }

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
  int _amountPaise = 0;
  _ConnectPhase _phase = _ConnectPhase.selecting;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 280), _run);
  }

  String get _amountDisplay =>
      '₹${(_amountPaise / 100).toStringAsFixed(_amountPaise % 100 == 0 ? 0 : 2)}';

  Future<void> _showVpaCopiedToast() async {
    if (!mounted) return;
    setState(() => _showVpaToast = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('VPA copied — paste now if the dialer asks'),
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _instructionCard() {
    if (_phase == _ConnectPhase.error || _phase == _ConnectPhase.selecting) {
      return const SizedBox.shrink();
    }
    final step1 = _phase.index >= _ConnectPhase.amountSent.index;
    final step2 = _phase.index >= _ConnectPhase.enterPin.index;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step2
                ? 'Step 2: Enter your UPI PIN when prompted.'
                : 'Step 1: Amount $_amountDisplay sent',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.cream,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (step2) ...[
            const SizedBox(height: 8),
            Text(
              'Type your PIN only in the Phone app — Zep Pay never sees or stores it.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
          if (step1 && !step2) ...[
            const SizedBox(height: 8),
            Text(
              'Next: the dialer will ask for your UPI PIN.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _amountFailSafeSheet() {
    if (_amountPaise <= 0 || _phase == _ConnectPhase.error) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textDim.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "If it doesn't auto-fill",
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textOnCreamMuted,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _amountDisplay,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.textOnCream,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _runOfflineDial({
    required PaymentDraft draft,
    required String dial,
    required String txId,
    required String refCode,
    required SecurityAudit audit,
    required dynamic tel,
    required NetworkInfo info,
    required PaymentRail rail,
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
    var dtmfAutoSent = false;
    var manualRequired = false;
    try {
      await Clipboard.setData(ClipboardData(text: draft.vpa));
      await session.markUpiCopied();
      if (rail == PaymentRail.ivr || isWebApp) {
        await _showVpaCopiedToast();
      }
      if (!mounted) return;
      setState(() {
        _phase = _ConnectPhase.amountSent;
        _label = autoActive ? 'Auto USSD…' : 'Opening Phone…';
        _detail = autoActive
            ? 'Follow the on-screen steps in Phone.\nTxn $refCode'
            : info.isJio
                ? '123PAY IVR opens for Jio. Amount is pre-dialed.\nTxn $refCode'
                : 'UPI ID copied. *99*1*3 sends to UPI ID.\nTxn $refCode';
      });
      await audit.dialOpened(txId, dial);
      await session.markDialOpened(dial);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _phase = _ConnectPhase.enterPin;
        _label = 'Complete in Phone';
        _detail = 'Enter your UPI PIN when the dialer asks.';
      });
      await tel.dial(dial);
      dtmfAutoSent = rail == PaymentRail.ivr || rail == PaymentRail.ussd;
      await session.markInPhone();
      if (!mounted) return;
      setState(() {
        _phase = _ConnectPhase.tracking;
        _label = 'Tracking payment…';
        _detail = autoActive
            ? 'Follow each USSD step in Phone, then return here.'
            : 'Complete the call in Phone, then return here to confirm.';
      });
      try {
        final report = await waitForDialerReturn();
        await session.recordDialSession(report);
        await audit.dialReturned(txId, report.longestStint, null);
        manualRequired = report.longestStint.inSeconds < 8;
      } catch (_) {
        manualRequired = true;
        await session.markAwaitingConfirm();
      }
      await DialTelemetry.log(
        txId: txId,
        rail: rail.name,
        amountPaise: draft.amountPaise,
        dtmfAutoSent: dtmfAutoSent,
        manualEntryRequired: manualRequired,
        manufacturer: info.manufacturer,
      );
      if (!mounted) return;
      setState(() => _phase = _ConnectPhase.selecting);
      context.go('/outcome');
    } finally {
      if (autoActive) {
        await UssdBridge.endSession();
      }
    }
  }

  Future<void> _runUpiIntent({
    required PaymentDraft draft,
    required String txId,
    required String refCode,
    required NetworkInfo info,
  }) async {
    setState(() {
      _label = 'Opening your UPI app';
      _detail = 'Complete payment in your UPI app.\nTxn $refCode';
    });
    await Clipboard.setData(ClipboardData(text: draft.vpa));
    await ref.read(paymentSessionProvider.notifier).markUpiCopied();
    await _showVpaCopiedToast();
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
        _phase = _ConnectPhase.error;
        _error =
            'Could not open a UPI app. Install GPay or PhonePe, then retry.';
      });
      return;
    }
    await ref.read(paymentSessionProvider.notifier).markAwaitingConfirm();
    if (mounted) context.go('/outcome');
  }

  Future<void> _runWebUssd({
    required PaymentDraft draft,
    required String dial,
    required String txId,
    required String refCode,
    required SecurityAudit audit,
    required dynamic tel,
  }) async {
    await Clipboard.setData(ClipboardData(text: draft.vpa));
    await ref.read(paymentSessionProvider.notifier).markUpiCopied();
    await _showVpaCopiedToast();
    if (!mounted) return;
    setState(() {
      _phase = _ConnectPhase.amountSent;
      _label = 'Dialing *99#…';
      _detail =
          'Paste the VPA if asked (already copied), then enter your PIN in Phone.\nTxn $refCode';
    });
    await audit.dialOpened(txId, dial);
    await ref.read(paymentSessionProvider.notifier).markDialOpened(dial);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    setState(() => _phase = _ConnectPhase.enterPin);
    await tel.dial(dial);
    await ref.read(paymentSessionProvider.notifier).markInPhone();
    setState(() => _phase = _ConnectPhase.tracking);
    try {
      final report = await waitForDialerReturn();
      await ref
          .read(paymentSessionProvider.notifier)
          .recordDialSession(report);
      await audit.dialReturned(txId, report.longestStint, null);
    } catch (_) {
      await ref.read(paymentSessionProvider.notifier).markAwaitingConfirm();
    }
    await DialTelemetry.log(
      txId: txId,
      rail: 'ussd',
      amountPaise: draft.amountPaise,
      dtmfAutoSent: false,
      manualEntryRequired: true,
    );
    if (mounted) context.go('/outcome');
  }

  Future<void> _run() async {
    final draft = ref.read(paymentDraftProvider);
    if (draft == null) {
      if (mounted) context.go('/home');
      return;
    }
    setState(() => _amountPaise = draft.amountPaise);
    final tel = ref.read(telephonyServiceProvider);
    final audit = await ref.read(securityAuditProvider.future);
    try {
      await tel.requestPermissions();
      final info = await tel.networkInfo();
      final resolution = RailEngine.resolve(info);

      if (!resolution.ok) {
        setState(() {
          _phase = _ConnectPhase.error;
          _error = resolution.error ??
              "Couldn't detect your carrier — retry or dial manually";
        });
        return;
      }

      final rail = resolution.rail!;
      assert(
        info.platform != 'android' || rail != PaymentRail.upiIntent,
        'Android must not use upiIntent',
      );

      ref.read(lastRailProvider.notifier).state = rail;
      _rail = rail;
      final dial = RailEngine.dialFor(
        rail,
        draft,
        manufacturer: info.manufacturer,
      );
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
        await _runUpiIntent(
          draft: draft,
          txId: tx.id,
          refCode: refCode,
          info: info,
        );
        return;
      }

      if (isWebApp && rail == PaymentRail.ussd) {
        await _runWebUssd(
          draft: draft,
          dial: dial,
          txId: tx.id,
          refCode: refCode,
          audit: audit,
          tel: tel,
        );
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
        rail: rail,
      );
    } catch (e) {
      setState(() {
        _phase = _ConnectPhase.error;
        _error = e.toString();
      });
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
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SignalArcs(size: 140),
                      const SizedBox(height: 24),
                      SoftSwitcher(
                        child: Text(
                          _label,
                          key: ValueKey(_label),
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: AppColors.textOnCream,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SoftSwitcher(
                        child: Text(
                          _detail.isEmpty ? 'Preparing offline rail…' : _detail,
                          key: ValueKey(_detail),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textOnCreamMuted,
                              ),
                        ),
                      ),
                      if (_txnId != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _txnId!,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.accent,
                                letterSpacing: 1.2,
                              ),
                        ),
                      ],
                      _instructionCard(),
                      if (steps.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        PaymentTrackCard(steps: steps),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                        const SizedBox(height: 16),
                        GlowButton(
                          label: 'RETRY',
                          onTap: () {
                            setState(() {
                              _error = null;
                              _phase = _ConnectPhase.selecting;
                            });
                            _run();
                          },
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.go('/home'),
                          child: const Text('Back home'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            _amountFailSafeSheet(),
          ],
        ),
      ),
    );
  }
}
