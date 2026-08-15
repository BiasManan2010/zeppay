import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/motion/app_motion.dart';
import '../../../core/platform.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/chrome.dart';
import '../../../core/widgets/ux.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/models.dart';
import '../../../data/services/providers.dart';
import '../pay/money_pages.dart';
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
      const SendHubScreen(),
      const SplitHomeScreen(),
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
                  color: selected ? AppColors.hero : AppColors.textDim,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: AppMotion.fast,
                style:
                    Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected ? AppColors.hero : AppColors.textDim,
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
    final profile = app.profile;
    final first = (profile?.name ?? '').trim().split(' ').first;
    final greeting = first.isEmpty || first.toLowerCase() == 'you'
        ? 'there'
        : first;
    final me = app.sessionPhone ?? '';
    final pending = app.requests
        .where((r) => r.status == RequestStatus.pending && r.toPhone == me)
        .length;

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
            RiseIn(
              child: Row(
              children: [
                const BrandMark(size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $greeting 👋',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(fontSize: 20),
                      ),
                      MoneyText(
                        profile?.balancePaise ?? 0,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.hero,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                RoundIconButton(
                  icon: Icons.notifications_none_rounded,
                  badge: pending > 0,
                  onTap: () => context.push('/inbox'),
                ),
                const SizedBox(width: 8),
                RoundIconButton(
                  icon: Icons.search_rounded,
                  onTap: () => context.push('/search'),
                ),
                const SizedBox(width: 8),
                RoundIconButton(
                  icon: Icons.help_outline_rounded,
                  onTap: () => context.push('/help'),
                ),
              ],
            ),
            ),
            const SizedBox(height: 14),
            RiseIn(
              delay: const Duration(milliseconds: 40),
              child: GiftNote(
                icon: Icons.bolt_rounded,
                title: 'You’re in · demo wallet live',
                body:
                    'Scan a QR before you leave this screen — the amount pad is already wired to your default spend chip.',
              ),
            ),
            const SizedBox(height: 14),
            if (!isAndroidDevice)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  'Offline *99# / 123PAY is Android-only. On iOS, Zep Pay opens the online UPI intent instead of silently failing.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.warning),
                ),
              ),
            RiseIn(
              delay: const Duration(milliseconds: 80),
              child: ScanHeroCard(onTap: () => context.push('/scan')),
            ),
            const SizedBox(height: 18),
            const _PeopleRow(),
            const SizedBox(height: 22),
            SectionHeader(title: 'Send Money', onAction: () => onOpenTab(1)),
            ActionTileRow(
              tiles: [
                ActionTile(
                  icon: Icons.phone_iphone_rounded,
                  label: 'To Mobile',
                  onTap: () => context.push('/pay/mobile'),
                ),
                ActionTile(
                  icon: Icons.alternate_email_rounded,
                  label: 'To UPI ID',
                  onTap: () => context.push('/pay/upi'),
                ),
                ActionTile(
                  icon: Icons.contacts_rounded,
                  label: 'To Contacts',
                  onTap: () => context.push('/pay/contacts'),
                ),
                ActionTile(
                  icon: Icons.call_received_rounded,
                  label: 'Receive',
                  onTap: () => context.push('/receive'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SectionHeader(
              title: 'Split & Settle',
              onAction: () => onOpenTab(2),
            ),
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
            SectionHeader(title: 'Quick Access', onAction: () => onOpenTab(3)),
            ActionTileRow(
              tiles: [
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
              ],
            ),
            const SizedBox(height: 22),
            Text('Recent', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (app.transactions.isEmpty)
              Text(
                'No payments yet. Scan to start.',
                style: Theme.of(context).textTheme.bodyMedium,
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
          onAction: () => context.push('/pay/contacts'),
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
