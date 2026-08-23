import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chrome.dart';
import '../../../core/widgets/pay_motion.dart';
import '../../../core/widgets/zep_coin_icon.dart';
import '../../../core/widgets/zep_components.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/models.dart';
import '../../../data/services/providers.dart';
import '../../../data/services/receipt_share.dart';
import '../../../data/services/sound_cue_service.dart';

class ConfirmScreen extends ConsumerStatefulWidget {
  const ConfirmScreen({super.key});

  @override
  ConsumerState<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends ConsumerState<ConfirmScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _coinCtrl;
  late final Animation<double> _coinScale;
  var _coinsRevealed = false;

  @override
  void initState() {
    super.initState();
    _coinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _coinScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.18), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 1.0), weight: 45),
    ]).animate(CurvedAnimation(parent: _coinCtrl, curve: Curves.easeOutBack));

    Future<void>.delayed(const Duration(milliseconds: 280), () async {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      await SoundCueService.instance.success();
      final coins = ref.read(lastCoinsEarnedProvider);
      if (coins > 0 && mounted) {
        setState(() => _coinsRevealed = true);
        _coinCtrl.forward(from: 0);
      }
      final draft = ref.read(paymentDraftProvider);
      final claim = ref.read(zepCardClaimOutcomeProvider);
      if (!mounted || draft?.zepCardPurchase != true) return;
      if (claim == ZepCardClaimOutcome.claimed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your Zep Card is linked — opening Card Details.'),
          ),
        );
        ref.read(zepCardClaimOutcomeProvider.notifier).state = null;
        _clear();
        context.go('/my-zep-card');
      } else if (claim == ZepCardClaimOutcome.noInventory) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment received, but no unclaimed Zep Cards are available right now. Contact support.',
            ),
            duration: Duration(seconds: 6),
          ),
        );
      } else if (claim == ZepCardClaimOutcome.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment succeeded but card linking failed. Try claiming manually with your NFC ID.',
            ),
            duration: Duration(seconds: 6),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _coinCtrl.dispose();
    super.dispose();
  }

  TxRecord? get _tx {
    final id = ref.read(pendingTxIdProvider);
    final txs = ref.read(appStoreProvider).transactions;
    if (id == null) return null;
    return txs.where((t) => t.id == id).firstOrNull;
  }

  void _clear() {
    ref.read(paymentDraftProvider.notifier).state = null;
    ref.read(pendingTxIdProvider.notifier).state = null;
    ref.read(lastCoinsEarnedProvider.notifier).state = 0;
  }

  void _openSplitPicker(TxRecord? tx, int amount, String who, String category) {
    final groups = ref.read(appStoreProvider).groups;
    if (groups.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Split with which group?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...groups.map(
              (g) => ListTile(
                title: Text(g.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  '${g.members.length} members',
                  style: const TextStyle(color: Colors.white54),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(splitPrefillProvider.notifier).state = SplitPrefill(
                    amountPaise: amount,
                    payeeName: who,
                    category: category,
                    title: tx?.note.isNotEmpty == true
                        ? tx!.note
                        : 'Payment to $who',
                  );
                  context.push('/split-bill');
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(paymentDraftProvider);
    final tx = _tx;
    final app = ref.watch(appStoreProvider);
    final amount = tx?.amountPaise ?? draft?.amountPaise ?? 0;
    final who = (tx?.payeeName.isNotEmpty == true)
        ? tx!.payeeName
        : (draft?.payeeName.isNotEmpty == true
              ? draft!.payeeName
              : (tx?.vpa ?? draft?.vpa ?? ''));
    final vpa = tx?.vpa ?? draft?.vpa ?? '';
    final category = tx?.category ?? draft?.category ?? 'other';
    final refCode =
        tx?.refCode.isNotEmpty == true ? tx!.refCode : (tx?.id ?? '');
    final when = tx?.createdAt ?? DateTime.now();
    final coins = ref.watch(lastCoinsEarnedProvider);
    final showSplit = app.groups.isNotEmpty;

    return Scaffold(
      
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const ConfettiBurst(),
                    const PaymentSuccessBurst(),
                    const SizedBox(height: 12),
                    Text(
                      'Payment Successful',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w800,
                          ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: amount / 100),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => Text(
                        '₹${value.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ),
                    Text(who, style: Theme.of(context).textTheme.titleMedium),
                    if (coins > 0 && _coinsRevealed)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: ScaleTransition(
                          scale: _coinScale,
                          child: InkWell(
                            onTap: () => context.push('/coins'),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.hero.withValues(alpha: 0.28),
                                    AppColors.heroDeep.withValues(alpha: 0.18),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppColors.hero.withValues(alpha: 0.55),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.hero.withValues(alpha: 0.25),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const ZepCoinIcon(size: 36),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '+$coins',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              color: AppColors.hero,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      const Text(
                                        'ZepCoins earned',
                                        style: TextStyle(
                                          color: AppColors.heroSoft,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.hero,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _row('Paid to', who),
                              _row('UPI ID', vpa),
                              _row('Zep Pay ID', refCode),
                              _row(
                                'On',
                                DateFormat('d MMM y, h:mm a').format(when),
                              ),
                              if ((tx?.note ?? draft?.note ?? '').isNotEmpty)
                                _row('Note', tx?.note ?? draft?.note ?? ''),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (showSplit)
                            _PostAction(
                              icon: Icons.call_split_rounded,
                              label: 'Split this expense',
                              onTap: () =>
                                  _openSplitPicker(tx, amount, who, category),
                            ),
                          _PostAction(
                            icon: Icons.ios_share_rounded,
                            label: 'Share screenshot',
                            onTap:
                                tx == null ? null : () => ReceiptShare.share(tx),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ZepPromoBanner(
                      headline: 'Spend ZepCoins in the Shop',
                      subtext: 'Demo partner offers — invented for the pitch',
                      chip: '${app.zepCoinBalance} coins',
                      onTap: () => context.push('/shop'),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        startPayment(
                          ref,
                          vpa: vpa,
                          amountPaise: amount,
                          payeeName: who,
                          note: tx?.note ?? draft?.note ?? '',
                          source: 'again',
                        );
                        ref.read(pendingTxIdProvider.notifier).state = null;
                        context.go('/pay/amount');
                      },
                      child: const Text('Send Again'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.hero,
                      ),
                      onPressed: () {
                        _clear();
                        context.go('/home');
                      },
                      child: const Text('Home'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(k, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Flexible(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostAction extends StatelessWidget {
  const _PostAction({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Icon(icon, color: AppColors.hero, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class FailedScreen extends ConsumerStatefulWidget {
  const FailedScreen({super.key});

  @override
  ConsumerState<FailedScreen> createState() => _FailedScreenState();
}

class _FailedScreenState extends ConsumerState<FailedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SoundCueService.instance.failure();
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(paymentDraftProvider);
    final id = ref.watch(pendingTxIdProvider);
    final tx = ref
        .watch(appStoreProvider)
        .transactions
        .where((t) => t.id == id)
        .firstOrNull;
    return Scaffold(
      
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const PaymentFailMark(),
              const SizedBox(height: 20),
              Text(
                'Payment Failed',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.danger,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${(draft?.amountRupees ?? 0).toStringAsFixed(2)} to ${draft?.payeeName.isNotEmpty == true ? draft!.payeeName : (draft?.vpa ?? '')}',
                textAlign: TextAlign.center,
              ),
              if ((tx?.refCode ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Txn ${tx!.refCode}'),
              ],
              const SizedBox(height: 8),
              const Text(
                'Nothing was taken in Zep Pay. Try again when the dialer session is ready.',
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              GlowButton(
                label: 'TRY AGAIN',
                onTap: () => context.go('/pay/amount'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  ref.read(paymentDraftProvider.notifier).state = null;
                  ref.read(pendingTxIdProvider.notifier).state = null;
                  context.go('/home');
                },
                child: const Text('Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PendingScreen extends ConsumerStatefulWidget {
  const PendingScreen({super.key});

  @override
  ConsumerState<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends ConsumerState<PendingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SoundCueService.instance.pending();
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(paymentDraftProvider);
    final id = ref.watch(pendingTxIdProvider);
    final tx = ref
        .watch(appStoreProvider)
        .transactions
        .where((t) => t.id == id)
        .firstOrNull;
    return Scaffold(
      
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const PaymentPendingMark(),
              const SizedBox(height: 20),
              Text(
                'Payment Pending',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.warning,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${(draft?.amountRupees ?? 0).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const Text(
                'Check SMS from your bank, or History in a minute.',
                textAlign: TextAlign.center,
              ),
              if ((tx?.refCode ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Txn ${tx!.refCode}'),
              ],
              const Spacer(),
              GlowButton(
                label: 'SEE HISTORY',
                onTap: () {
                  ref.read(paymentDraftProvider.notifier).state = null;
                  ref.read(pendingTxIdProvider.notifier).state = null;
                  context.go('/history');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
