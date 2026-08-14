import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/platform.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/chrome.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/models.dart';
import '../../../data/services/providers.dart';
import '../../../data/services/telephony_service.dart';
import '../pay/pay_friends_screen.dart';
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
      const PayFriendsScreen(),
      const SplitHomeScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: _DockedNav(
        tab: _tab,
        onTab: _go,
        onScan: () => context.push('/scan'),
      ),
    );
  }
}

class _DockedNav extends StatelessWidget {
  const _DockedNav(
      {required this.tab, required this.onTab, required this.onScan});

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
                        color: AppColors.surfaceBorder.withValues(alpha: 0.8))),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 24,
                      offset: const Offset(0, -8)),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom),
                child: Row(
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      selected: tab == 0,
                      onTap: () => onTab(0),
                    ),
                    _NavItem(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Send',
                      selected: tab == 1,
                      onTap: () => onTab(1),
                    ),
                    const SizedBox(width: 72),
                    _NavItem(
                      icon: Icons.groups_rounded,
                      label: 'Split',
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
            child: Center(child: ScanOrbButton(size: 68, onTap: onScan)),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});
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
              Icon(icon,
                  color: selected ? AppColors.hero : AppColors.textDim,
                  size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected ? AppColors.hero : AppColors.textDim,
                      letterSpacing: 0.2,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
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
    final profile = app.profile;
    final first = (profile?.name ?? '').trim().split(' ').first;
    final greeting =
        first.isEmpty || first.toLowerCase() == 'you' ? 'there' : first;
    final me = app.sessionPhone ?? '';
    final pending = app.requests
        .where((r) => r.status == RequestStatus.pending && r.toPhone == me)
        .length;
    final net = ref.watch(networkInfoProvider);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.85),
          radius: 1.15,
          colors: [AppColors.homeWash, AppColors.base],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
          children: [
            Row(
              children: [
                ProfileAvatar(name: profile?.name ?? 'Z', size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $greeting 👋',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontSize: 20),
                      ),
                      Text(
                        'Welcome back!',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                RoundIconButton(
                  icon: Icons.notifications_none_rounded,
                  badge: pending > 0,
                  onTap: () => context.push('/requests'),
                ),
                const SizedBox(width: 8),
                RoundIconButton(
                  icon: Icons.help_outline_rounded,
                  onTap: () => _help(context, net),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (!isAndroidDevice)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.45)),
                ),
                child: Text(
                  'Offline *99# / 123PAY is Android-only. On iOS, Zep Pay opens the online UPI intent instead of silently failing.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.warning),
                ),
              ),
            Hero(
              tag: 'scan-hero',
              child: ScanHeroCard(onTap: () => context.push('/scan')),
            ),
            const SizedBox(height: 22),
            SectionHeader(title: 'Send Money', onAction: () => onOpenTab(1)),
            ActionTileRow(
              tiles: [
                ActionTile(
                  icon: Icons.person_outline_rounded,
                  label: 'To Mobile /\nUPI ID',
                  onTap: () => context.push('/pay-friends'),
                ),
                ActionTile(
                  icon: Icons.contacts_rounded,
                  label: 'To Contacts',
                  onTap: () => context.push('/pay-friends'),
                ),
                ActionTile(
                  icon: Icons.qr_code_2_rounded,
                  label: 'Scan & Pay',
                  onTap: () => context.push('/scan'),
                ),
                ActionTile(
                  icon: Icons.account_balance_rounded,
                  label: 'To Bank A/c',
                  onTap: () => _self(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SectionHeader(
                title: 'Split & Settle', onAction: () => onOpenTab(2)),
            ActionTileRow(
              tiles: [
                ActionTile(
                  icon: Icons.group_add_rounded,
                  label: 'Split Bill',
                  onTap: () {
                    final groups = ref.read(appStoreProvider).groups;
                    if (groups.isNotEmpty) {
                      context.push('/split/${groups.first.id}/add');
                    } else {
                      onOpenTab(2);
                    }
                  },
                ),
                ActionTile(
                  icon: Icons.pie_chart_outline_rounded,
                  label: 'My Groups',
                  onTap: () => onOpenTab(2),
                ),
                ActionTile(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Settle Up',
                  onTap: () {
                    final groups = ref.read(appStoreProvider).groups;
                    if (groups.isNotEmpty) {
                      context.push('/split/${groups.first.id}');
                    } else {
                      onOpenTab(2);
                    }
                  },
                ),
                ActionTile(
                  icon: Icons.assignment_outlined,
                  label: 'Activity',
                  onTap: () => context.push('/history'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            HapticScale(
              onTap: () => _offlineSheet(context, net),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                      child: const Icon(Icons.cell_tower_rounded,
                          color: AppColors.hero),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.hero.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Offline Only',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.hero,
                                    letterSpacing: 0,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('Offline Payment',
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(
                            'Use *99# / 123PAY when data drops.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textDim),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            SectionHeader(title: 'Quick Access', onAction: () => onOpenTab(3)),
            ActionTileRow(
              tiles: [
                ActionTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Check Balance',
                  onTap: () => _balanceSheet(context, profile),
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
                  onTap: () => onOpenTab(3),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text('Recent', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (app.transactions.isEmpty)
              Text('No payments yet. Scan to start.',
                  style: Theme.of(context).textTheme.bodyMedium)
            else
              ...app.transactions.take(4).map((tx) => _TxTile(tx: tx)),
          ],
        ),
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Linked account', style: Theme.of(ctx).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(profile?.bankName ?? '—',
                style: Theme.of(ctx).textTheme.headlineMedium),
            Text('UPI  ${profile?.upiId ?? ''}',
                style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 16),
            MoneyText(profile?.balancePaise ?? 0,
                style: Theme.of(ctx).textTheme.displayMedium),
            const SizedBox(height: 8),
            Text('**** ${profile?.accountLast4 ?? '••••'}',
                style: Theme.of(ctx).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  void _help(BuildContext context, AsyncValue<NetworkInfo> net) {
    _offlineSheet(context, net);
  }

  void _offlineSheet(BuildContext context, AsyncValue<NetworkInfo> net) {
    final rail = net.maybeWhen(
      data: (info) => isIosDevice
          ? 'iOS · online UPI fallback'
          : '${info.operator.isEmpty ? 'Carrier' : info.operator} · ${info.isJio ? '123PAY' : '*99#'}',
      orElse: () => '*99# / 123PAY',
    );
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Offline Payment',
                style: Theme.of(ctx).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Zep Pay routes through *99# (USSD) when your carrier supports it, and UPI 123PAY IVR for Jio and 4G-only SIMs. You only confirm with biometrics and enter your UPI PIN.',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text('This device · $rail',
                style: Theme.of(ctx)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: AppColors.hero)),
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
        decoration: BoxDecoration(color: color, shape: BoxShape.circle));
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
      trailing: MoneyText(tx.amountPaise,
          style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
