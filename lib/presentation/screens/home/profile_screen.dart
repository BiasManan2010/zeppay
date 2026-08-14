import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/chrome.dart';
import '../../../data/local/app_store.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(appStoreProvider).profile;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
          children: [
            Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            SurfaceCard(
              child: Row(
                children: [
                  ProfileAvatar(name: profile?.name ?? 'Z', size: 64),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.name.isNotEmpty == true
                              ? profile!.name
                              : 'You',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          profile?.upiId ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          profile?.phone ?? '',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SurfaceCard(
              onTap: () => context.push('/receive'),
              child: _row(
                context,
                Icons.qr_code_2_rounded,
                'My QR / UPI ID',
                profile?.upiId.isNotEmpty == true
                    ? profile!.upiId
                    : 'Set a UPI ID to receive',
              ),
            ),
            const SizedBox(height: 10),
            SurfaceCard(
              onTap: () => context.push('/balance'),
              child: _row(
                context,
                Icons.account_balance_wallet_outlined,
                'Linked bank',
                profile?.bankName ?? '—',
              ),
            ),
            const SizedBox(height: 10),
            SurfaceCard(
              onTap: () => context.push('/analytics'),
              child: _row(
                context,
                Icons.insights_rounded,
                'Spending',
                'Charts from this device',
              ),
            ),
            const SizedBox(height: 10),
            SurfaceCard(
              onTap: () => context.push('/history'),
              child: _row(
                context,
                Icons.history_rounded,
                'Transaction history',
                'All rails, all statuses',
              ),
            ),
            const SizedBox(height: 10),
            SurfaceCard(
              onTap: () => context.push('/inbox'),
              child: _row(
                context,
                Icons.notifications_none_rounded,
                'Inbox',
                'Autopay and split alerts',
              ),
            ),
            const SizedBox(height: 10),
            SurfaceCard(
              onTap: () => context.push('/requests'),
              child: _row(
                context,
                Icons.inbox_rounded,
                'Pending requests',
                'Accept or pay',
              ),
            ),
            const SizedBox(height: 10),
            SurfaceCard(
              onTap: () => context.push('/autopay'),
              child: _row(
                context,
                Icons.event_repeat_rounded,
                'Autopay',
                'Mandates and limits',
              ),
            ),
            const SizedBox(height: 10),
            SurfaceCard(
              onTap: () => context.push('/settings'),
              child: _row(
                context,
                Icons.settings_outlined,
                'Settings',
                'Twilio Verify URL',
              ),
            ),
            SurfaceCard(
              onTap: () => context.push('/search'),
              child: _row(
                context,
                Icons.search_rounded,
                'Search',
                'Payments and split bills',
              ),
            ),
            const SizedBox(height: 10),
            SurfaceCard(
              onTap: () => context.push('/categories'),
              child: _row(
                context,
                Icons.pie_chart_outline_rounded,
                'Categories',
                'Split spend by type',
              ),
            ),
            const SizedBox(height: 10),
            SurfaceCard(
              onTap: () => context.push('/help'),
              child: _row(
                context,
                Icons.help_outline_rounded,
                'How it works',
                '*99# / 123PAY walkthrough',
              ),
            ),
            const SizedBox(height: 24),
            GlowButton(
              label: 'SIGN OUT',
              onTap: () => ref.read(appStoreProvider.notifier).logout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.hero.withValues(alpha: 0.12),
          ),
          child: Icon(icon, color: AppColors.hero),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppColors.textDim),
      ],
    );
  }
}
