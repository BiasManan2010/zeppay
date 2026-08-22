import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/motion/app_motion.dart';
import '../../../core/platform.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/chrome.dart';
import '../../../core/widgets/illustrations.dart';
import '../../../core/widgets/zep_components.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/models.dart';
import '../../../data/services/payment_session.dart';
import '../../../data/services/providers.dart';
import '../pay/payment_services_hub.dart';
import '../pay/history_screen.dart';
import '../split/split_home_screen.dart';
import 'profile_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  var _tab = 0;

  void _go(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(onOpenTab: _go),
      const PaymentServicesHubScreen(embedded: true),
      const HistoryScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      extendBody: true,
      body: pages[_tab],
      bottomNavigationBar: _DockedNav(
        tab: _tab,
        onTab: _go,
        onScan: () => context.push('/scan'),
      ),
    );
  }
}

class _DockedNav extends StatelessWidget {
  const _DockedNav({
    required this.tab,
    required this.onTab,
    required this.onScan,
  });

  final int tab;
  final ValueChanged<int> onTab;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92 + MediaQuery.paddingOf(context).bottom,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.navBar,
                border: Border(
                  top: BorderSide(
                    color: AppColors.surfaceBorder.withValues(alpha: 0.8),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom,
                ),
                child: Row(
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      selected: tab == 0,
                      onTap: () => onTab(0),
                    ),
                    _NavItem(
                      icon: Icons.grid_view_rounded,
                      label: 'Pay',
                      selected: tab == 1,
                      onTap: () => onTab(1),
                    ),
                    const SizedBox(width: 72),
                    _NavItem(
                      icon: Icons.history_rounded,
                      label: 'History',
                      selected: tab == 2,
                      onTap: () => onTab(2),
                    ),
                    _NavItem(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      selected: tab == 3,
                      onTap: () => onTab(3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -22,
            left: 0,
            right: 0,
            child: Center(child: ZepOrangeFab(onTap: onScan)),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
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
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.12 : 1,
                duration: AppMotion.fast,
                curve: AppMotion.out,
                child: Icon(
                  icon,
                  color: selected ? AppColors.accent : AppColors.textDim,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: AppMotion.fast,
                style:
                    Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected ? AppColors.accent : AppColors.textDim,
                      letterSpacing: 0.2,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ) ??
                    const TextStyle(),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab({required this.onOpenTab});
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStoreProvider);
    final track = ref.watch(paymentSessionProvider).value?.track;
    if (track?.needsConfirmation == true &&
        ref.read(pendingTxIdProvider) != track!.txId) {
      resumePendingPaymentTrack(ref);
    }
    final profile = app.profile;
    final me = app.sessionPhone ?? '';
    final pending = app.requests
        .where((r) => r.status == RequestStatus.pending && r.toPhone == me)
        .length;
    final unread = app.notifications.where((n) => !n.read).length;

    return ColoredBox(
      color: AppColors.cream,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 140),
          children: [
            ZepHeaderBar(
              name: profile?.name ?? '',
              upiId: profile?.upiId ?? '',
              unreadCount: unread,
              onNotifications: () => context.push('/inbox'),
            ),
            const SizedBox(height: 8),
            ZepBankCard(
              bankName: profile?.bankName ?? '',
              accountLast4: profile?.accountLast4 ?? '',
              balancePaise: profile?.balancePaise ?? 0,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ZepQuickAction(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Scan',
                    tint: AppColors.accent,
                    onTap: () => context.push('/scan'),
                  ),
                  ZepQuickAction(
                    icon: Icons.send_rounded,
                    label: 'Send',
                    tint: const Color(0xFF5B8DEF),
                    onTap: () => onOpenTab(1),
                  ),
                  ZepQuickAction(
                    icon: Icons.call_split_rounded,
                    label: 'Split',
                    tint: const Color(0xFF2D8A5E),
                    onTap: () => context.push('/split'),
                  ),
                ],
              ),
            ),
            if (track?.needsConfirmation == true) ...[
              const SizedBox(height: 12),
              RiseIn(
                child: HapticScale(
                  onTap: () => context.push('/outcome'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.hourglass_top_rounded,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Confirm what *99# showed',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(color: AppColors.warning),
                              ),
                              Text(
                                '${track!.refCode} · ₹${(track.amountPaise / 100).toStringAsFixed(0)} → ${track.vpa}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (pending > 0) ...[
              ZepSectionHeader(
                title: 'Action needed',
                badge: pending,
                onViewAll: () => context.push('/requests'),
              ),
              ...app.requests
                  .where(
                    (r) =>
                        r.status == RequestStatus.pending && r.toPhone == me,
                  )
                  .take(3)
                  .map(
                    (r) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ZepDarkCard(
                        onTap: () => context.push('/requests'),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.fromName.isEmpty
                                        ? r.fromPhone
                                        : r.fromName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '₹${(r.amountPaise / 100).toStringAsFixed(0)} requested',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              onPressed: () => context.push('/requests'),
                              child: Text(
                                'Pay ₹${(r.amountPaise / 100).toStringAsFixed(0)}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
            const SizedBox(height: 8),
            ZepPromoBanner(
              headline: 'ZepCoins & Shop',
              subtext: 'Earn coins on every payment — redeem demo offers',
              chip: '${app.zepCoinBalance} coins',
              onTap: () => context.push('/coins'),
            ),
            const SizedBox(height: 16),
            if (isWebApp)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'iOS offline rails have a lower ceiling than Android — paste VPA in Phone when asked.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else if (isIosDevice)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Offline *99# / 123PAY is strongest on Android. iOS uses UPI app handoff.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                      ),
                ),
              ),
            const SizedBox(height: 12),
            const _PeopleRow(),
            const SizedBox(height: 16),
            SectionHeader(title: 'Split & Settle', onAction: () => context.push('/split')),
            ActionTileRow(
              tiles: [
                ActionTile(
                  icon: Icons.group_add_rounded,
                  label: 'Split Bill',
                  onTap: () => context.push('/split-bill'),
                ),
                ActionTile(
                  icon: Icons.pie_chart_outline_rounded,
                  label: 'My Groups',
                  onTap: () => context.push('/split'),
                ),
                ActionTile(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Settle Up',
                  onTap: () => context.push('/settle'),
                ),
                ActionTile(
                  icon: Icons.assignment_outlined,
                  label: 'Activity',
                  onTap: () => context.push('/split-activity'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (supportsOfflineRails) ...[
              HapticScale(
              onTap: () => context.push('/offline'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.hero.withValues(alpha: 0.14),
                      ),
                      child: const Icon(
                        Icons.cell_tower_rounded,
                        color: AppColors.hero,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.hero.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Offline Only',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppColors.hero,
                                    letterSpacing: 0,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Offline Payment',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Use *99# / 123PAY when data drops.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textDim,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            ],
            SectionHeader(title: 'Quick Access', onAction: () => onOpenTab(3)),
            ActionTileRow(
              tiles: [
                if (supportsOfflineRails)
                  ActionTile(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Check Balance',
                    onTap: () => context.push('/balance'),
                  ),
                ActionTile(
                  icon: Icons.history_rounded,
                  label: 'Transaction History',
                  onTap: () => context.push('/history'),
                ),
                ActionTile(
                  icon: Icons.upload_file_outlined,
                  label: 'Pending Requests',
                  badge: pending > 0 ? '$pending' : null,
                  onTap: () => context.push('/requests'),
                ),
                ActionTile(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () => context.push('/settings'),
                ),
                if (isWebApp)
                  ActionTile(
                    icon: Icons.event_repeat_rounded,
                    label: 'Autopay',
                    onTap: () => context.push('/autopay'),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Text('Recent', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (app.transactions.isEmpty)
              const EmptyScene(
                art: ZepArt.emptyPay,
                message: 'No payments yet. Scan to start.',
                size: 140,
              )
            else
              ...app.transactions.take(4).map(
                    (tx) => _TxTile(
                      tx: tx,
                      onTap: () => context.push('/history/${tx.id}'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HapticScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.hero.withValues(alpha: 0.16),
              ),
              child: Icon(icon, color: AppColors.hero, size: 22),
            ),
            const SizedBox(height: 12),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Text(hint, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
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
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile({required this.tx, this.onTap});
  final TxRecord tx;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: TxStatusDot(tx.status),
      title: Text(tx.payeeName.isEmpty ? tx.vpa : tx.payeeName),
      subtitle: Text(DateFormat('d MMM, h:mm a').format(tx.createdAt)),
      trailing: MoneyText(
        tx.amountPaise,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _PeopleRow extends ConsumerWidget {
  const _PeopleRow();

  List<SavedPayee> _people(AppState app) {
    if (app.payees.isNotEmpty) {
      final fav = app.payees.where((p) => p.favorite);
      final rest = app.payees.where((p) => !p.favorite);
      return [...fav, ...rest].take(12).toList();
    }
    final seen = <String>{};
    final out = <SavedPayee>[];
    for (final tx in app.transactions) {
      if (tx.vpa.isEmpty || !seen.add(tx.vpa)) continue;
      out.add(
        SavedPayee(
          vpa: tx.vpa,
          name: tx.payeeName.isEmpty ? tx.vpa : tx.payeeName,
        ),
      );
      if (out.length >= 12) break;
    }
    return out;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = _people(ref.watch(appStoreProvider));
    if (people.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'People',
          onAction: () => context.push(
            supportsDeviceContacts ? '/pay/contacts' : '/pay/upi',
          ),
        ),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: people.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final p = people[i];
              final label = p.name.trim().isNotEmpty ? p.name.trim() : p.vpa;
              final letter = label.isEmpty
                  ? '?'
                  : label.characters.first.toUpperCase();
              return InkWell(
                onTap: () {
                  startPayment(
                    ref,
                    vpa: p.vpa,
                    amountPaise: 0,
                    payeeName: p.name,
                    source: 'people',
                  );
                  context.push('/pay/amount');
                },
                child: SizedBox(
                  width: 68,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.hero.withValues(alpha: 0.18),
                        child: Text(
                          letter,
                          style: const TextStyle(
                            color: AppColors.hero,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        (p.name.trim().isEmpty ? p.vpa : p.name)
                            .split(' ')
                            .first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
