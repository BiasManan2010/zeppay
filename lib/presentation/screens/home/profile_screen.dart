import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/motion/app_motion.dart';
import '../../../core/platform.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/chrome.dart';
import '../../../data/local/app_store.dart';
import '../../../data/services/profile_media.dart';
import '../../../data/services/providers.dart';
import '../../../data/services/security_audit.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _pickPhoto(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: AppColors.hero),
                title: const Text('Photo library'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_camera_rounded, color: AppColors.hero),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;
    final path = await ProfileMedia.pick(source: source);
    if (path == null) return;
    final p = ref.read(appStoreProvider).profile;
    if (p == null) return;
    await ref.read(appStoreProvider.notifier).updateProfile(
          p.copyWith(photoPath: path),
        );
    HapticFeedback.mediumImpact();
  }

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final p = ref.read(appStoreProvider).profile;
    if (p == null) return;
    final ctrl = TextEditingController(text: p.name);
    final next = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Your name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Name people see'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (next == null || next.isEmpty) return;
    await ref.read(appStoreProvider.notifier).updateProfile(p.copyWith(name: next));
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(appStoreProvider).profile;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
          children: [
            Row(
              children: [
                Text(
                  profile?.name.isNotEmpty == true ? profile!.name : 'Profile',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.qr_code_2_rounded),
                  onPressed: () => context.push('/receive'),
                  tooltip: 'Receive money',
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.account_balance_outlined),
              title: Text(profile?.bankName.isNotEmpty == true
                  ? profile!.bankName
                  : 'Payment methods'),
              subtitle: Text(
                profile?.accountLast4.isNotEmpty == true
                    ? '•••• ${profile!.accountLast4}'
                    : 'Link in onboarding',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/settings'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => context.push('/receive'),
              icon: const Icon(Icons.qr_code_rounded),
              label: const Text('Download / Share QR'),
            ),
            const SizedBox(height: 24),
            RiseIn(
              delay: const Duration(milliseconds: 40),
              child: Column(
                children: [
                  HapticScale(
                    onTap: () => _pickPhoto(context, ref),
                    child: ProfileAvatar(
                      name: profile?.name ?? '',
                      photoPath: profile?.photoPath ?? '',
                      size: 96,
                      showEdit: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  HapticScale(
                    onTap: () => _editName(context, ref),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          profile?.name.isNotEmpty == true
                              ? profile!.name
                              : 'Add your name',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: AppColors.textDim,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile?.upiId.isNotEmpty == true
                        ? profile!.upiId
                        : 'No UPI ID yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    profile?.phone ?? '',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            RiseIn(
              delay: const Duration(milliseconds: 80),
              child: GlowButton(
                label: 'MY QR',
                onTap: () => context.push('/receive'),
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
            const SizedBox(height: 10),
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
                isWebApp
                    ? 'Scan, amount, then your UPI app'
                    : '*99# / 123PAY walkthrough',
              ),
            ),
            const SizedBox(height: 24),
            GlowButton(
              label: 'SIGN OUT',
              onTap: () async {
                final audit = await ref.read(securityAuditProvider.future);
                await audit.logout();
                await ref.read(appStoreProvider.notifier).logout();
              },
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
