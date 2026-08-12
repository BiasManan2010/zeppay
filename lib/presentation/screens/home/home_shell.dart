import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/models.dart';
import '../../../data/services/providers.dart';
import '../pay/autopay_screen.dart';
import '../pay/requests_screen.dart';
import '../split/split_home_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      _HomeTab(),
      SplitHomeScreen(),
      RequestsScreen(),
      AutopayScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SizedBox(
          width: 74,
          height: 74,
          child: HapticScale(
            onTap: () => context.push('/scan'),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.heroGlow,
                boxShadow: [
                  BoxShadow(color: AppColors.hero.withValues(alpha: 0.45), blurRadius: 22),
                ],
                border: Border.all(color: AppColors.hero, width: 1.2),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.white),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: AppColors.baseAlt,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          children: [
            _NavItem(icon: Icons.bolt_rounded, label: 'Home', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
            _NavItem(icon: Icons.groups_rounded, label: 'Split', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
            const SizedBox(width: 72),
            _NavItem(icon: Icons.inbox_rounded, label: 'Requests', selected: _tab == 2, onTap: () => setState(() => _tab = 2)),
            _NavItem(icon: Icons.event_repeat_rounded, label: 'Autopay', selected: _tab == 3, onTap: () => setState(() => _tab = 3)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? AppColors.hero : AppColors.textDim, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: selected ? AppColors.hero : AppColors.textDim,
                        letterSpacing: 0.4,
                      )),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStoreProvider);
    final profile = app.profile;
    final net = ref.watch(networkInfoProvider);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Row(
            children: [
              Text('ZEP PAY', style: Theme.of(context).textTheme.labelLarge),
              const Spacer(),
              Text(profile?.name ?? '', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 18),
          Text('BALANCE', style: Theme.of(context).textTheme.labelSmall),
          MoneyText(
            profile?.balancePaise ?? 0,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          net.when(
            data: (info) => Text(
              Platform.isIOS
                  ? 'iOS · online UPI fallback'
                  : '${info.operator.isEmpty ? 'Carrier' : info.operator} · ${info.isJio ? '123PAY' : '*99#'}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 22),
          if (!Platform.isAndroid)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.45)),
              ),
              child: Text(
                'Offline *99# / 123PAY is Android-only. On iOS, Zep Pay opens the online UPI intent instead of silently failing.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.warning),
              ),
            ),
          Hero(
            tag: 'scan-hero',
            child: ScanHeroCard(onTap: () => context.push('/scan')),
          ),
          const SizedBox(height: 22),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              _Quick(icon: Icons.people_alt_rounded, label: 'Pay Friends', onTap: () => context.push('/pay-friends')),
              _Quick(icon: Icons.account_balance_rounded, label: 'Bank / Self', onTap: () => _self(context, ref)),
              _Quick(icon: Icons.account_balance_wallet_rounded, label: 'Check Balance', onTap: () => _balanceSheet(context, profile)),
              _Quick(icon: Icons.receipt_long_rounded, label: 'History', onTap: () => context.push('/history')),
            ],
          ),
          const SizedBox(height: 22),
          Text('RECENT', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          if (app.transactions.isEmpty)
            Text('No payments yet. Scan to start.', style: Theme.of(context).textTheme.bodyMedium)
          else
            ...app.transactions.take(4).map((tx) => _TxTile(tx: tx)),
        ],
      ),
    );
  }

  void _self(BuildContext context, WidgetRef ref) {
    final me = ref.read(appStoreProvider).profile;
    if (me == null) return;
    ref.read(paymentDraftProvider.notifier).state = PaymentDraft(
      vpa: me.upiId,
      amountPaise: 0,
      payeeName: 'Self',
      source: 'self',
    );
    context.push('/pay-friends');
  }

  void _balanceSheet(BuildContext context, UserProfile? profile) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Linked account', style: Theme.of(ctx).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(profile?.bankName ?? '—', style: Theme.of(ctx).textTheme.headlineMedium),
            Text('UPI  ${profile?.upiId ?? ''}', style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 16),
            MoneyText(profile?.balancePaise ?? 0, style: Theme.of(ctx).textTheme.displayMedium),
            const SizedBox(height: 8),
            Text('**** ${profile?.accountLast4 ?? '••••'}', style: Theme.of(ctx).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _Quick extends StatelessWidget {
  const _Quick({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.hero),
          const Spacer(),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class TxStatusDot extends StatelessWidget {
  const TxStatusDot(this.status, {super.key});
  final TxStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      TxStatus.success => AppColors.hero,
      TxStatus.pending => AppColors.warning,
      TxStatus.failed => AppColors.danger,
    };
    return Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile({required this.tx});
  final TxRecord tx;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: TxStatusDot(tx.status),
      title: Text(tx.payeeName.isEmpty ? tx.vpa : tx.payeeName),
      subtitle: Text(DateFormat('d MMM, h:mm a').format(tx.createdAt)),
      trailing: MoneyText(tx.amountPaise, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
