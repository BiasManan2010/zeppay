import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/motion/app_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/chrome.dart';
import '../../../data/local/app_store.dart';
import '../../../data/services/profile_media.dart';

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
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
          children: [
            RiseIn(
              child: Text(
                'You',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
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
              onTap: () => context.push('/history'),
              child: _row(context, Icons.history_rounded, 'Activity', 'Payments on this phone'),
            ),
            const SizedBox(height: 10),
            SurfaceCard(
              onTap: () => context.push('/settings'),
              child: _row(context, Icons.settings_outlined, 'Settings', 'Name and OTP'),
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
