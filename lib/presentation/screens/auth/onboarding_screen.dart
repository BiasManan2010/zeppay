import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/chrome.dart';
import '../../../core/widgets/ux.dart';
import '../../../data/local/app_store.dart';
import '../../../data/services/profile_media.dart';
import '../../../data/services/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _name = TextEditingController();
  final _upi = TextEditingController();
  final _bank = TextEditingController(text: 'SBI');
  final _last4 = TextEditingController();
  var _step = 0;
  var _busy = false;
  var _upiTouched = false;
  String? _error;

  static const _banks = ['SBI', 'HDFC', 'ICICI', 'Axis', 'Kotak', 'Other'];

  @override
  void initState() {
    super.initState();
    final p = ref.read(appStoreProvider).profile;
    if (p != null && p.name.isNotEmpty && p.name.toLowerCase() != 'you') {
      _name.text = p.name;
    }
    if (p != null && p.upiId.contains('@')) {
      _upi.text = p.upiId;
      _upiTouched = true;
    }
    if (p != null && p.bankName.isNotEmpty && p.bankName != 'Linked bank') {
      _bank.text = p.bankName;
    }
    if (!_upiTouched) {
      final slug = _name.text
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (slug.isNotEmpty) _upi.text = '$slug@upi';
    }
    _name.addListener(_syncHandle);
  }

  void _syncHandle() {
    if (_upiTouched) {
      setState(() {});
      return;
    }
    final slug = _name.text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    _upi.text = slug.isEmpty ? '' : '$slug@upi';
    setState(() {});
  }

  @override
  void dispose() {
    _name.removeListener(_syncHandle);
    _name.dispose();
    _upi.dispose();
    _bank.dispose();
    _last4.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_step == 0) {
      if (_name.text.trim().isEmpty) {
        setState(() => _error = 'What should we call you?');
        return;
      }
      setState(() {
        _step = 1;
        _error = null;
      });
      return;
    }
    if (_step == 1) {
      if (!_upi.text.contains('@')) {
        setState(() => _error = 'A valid UPI ID is required');
        return;
      }
      setState(() {
        _step = 2;
        _error = null;
      });
      return;
    }
    setState(() => _busy = true);
    final bio = ref.read(biometricServiceProvider);
    final available = await bio.isAvailable();
    final ok = !available ||
        await bio.confirm(
          reason: 'Lock this phone — without it anyone holding it can pay',
        );
    if (!ok) {
      setState(() {
        _busy = false;
        _error =
            'Skip this and this phone can pay without your face. Enable it to keep the wallet.';
      });
      return;
    }
    await ref.read(appStoreProvider.notifier).completeOnboarding(
          name: _name.text.trim(),
          upiId: _upi.text.trim().toLowerCase(),
          bankName:
              _bank.text.trim().isEmpty ? 'SBI' : _bank.text.trim(),
          accountLast4: _last4.text.trim(),
        );
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Put your name on it.', 'Handle + bank.', 'Lock the phone.'];
    final bodies = [
      'This is what people see on your QR. Tap the photo to change it.',
      'Most people pay from SBI / HDFC / ICICI. We parked SBI. Change it if that’s not you.',
      'Without this, anyone with the phone can fire *99#. You’re one confirm from sealing it.',
    ];
    return AuthBackdrop(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GoalBar(
              done: 2 + _step,
              total: 4,
              label: 'Number already in · finish your card',
            ),
            const SizedBox(height: 16),
            StepPills(count: 3, index: _step),
            const SizedBox(height: 20),
            Text(titles[_step], style: Theme.of(context).textTheme.displayMedium)
                .animate(key: ValueKey(_step))
                .fadeIn(duration: 280.ms)
                .slideY(begin: 0.04),
            const SizedBox(height: 8),
            Text(
              bodies[_step],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 16),
            ZepCardPreview(
              name: _name.text,
              handle: _upi.text,
              bank: _bank.text,
            ),
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: _step == 0
                    ? GlassPanel(
                        key: const ValueKey('you'),
                        child: Column(
                          children: [
                            HapticScale(
                              onTap: () async {
                                final path = await ProfileMedia.pick();
                                if (path == null) return;
                                final p = ref.read(appStoreProvider).profile;
                                if (p == null) return;
                                await ref
                                    .read(appStoreProvider.notifier)
                                    .updateProfile(p.copyWith(photoPath: path));
                                if (mounted) setState(() {});
                              },
                              child: ProfileAvatar(
                                name: _name.text,
                                photoPath: ref
                                        .watch(appStoreProvider)
                                        .profile
                                        ?.photoPath ??
                                    '',
                                size: 84,
                                showEdit: true,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'YOUR NAME',
                                hintText: 'Manan',
                              ),
                            ),
                          ],
                        ),
                      )
                    : _step == 1
                        ? GlassPanel(
                            key: const ValueKey('upi'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _upi,
                                  onChanged: (_) {
                                    _upiTouched = true;
                                    setState(() {});
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'UPI ID',
                                    hintText: 'you@okaxis',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'BANK',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                const SizedBox(height: 8),
                                ChoicePills(
                                  selected: _banks.contains(_bank.text)
                                      ? _bank.text
                                      : 'Other',
                                  onPick: (id) {
                                    _bank.text = id == 'Other' ? '' : id;
                                    setState(() {});
                                  },
                                  options: [
                                    for (final b in _banks) (b, b),
                                  ],
                                ),
                                if (_bank.text.isEmpty ||
                                    !_banks.contains(_bank.text)) ...[
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _bank,
                                    decoration: const InputDecoration(
                                      labelText: 'BANK NAME',
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _last4,
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  decoration: const InputDecoration(
                                    labelText: 'ACCOUNT LAST 4 (OPTIONAL)',
                                    counterText: '',
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const Center(
                            key: ValueKey('face'),
                            child: FaceGlow(),
                          ),
              ),
              ),
            ),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
              const SizedBox(height: 8),
            ],
            if (_step == 2)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: LossNote(
                  text:
                      'Leave now and this card is unfinished — no *99# handle, no face lock.',
                ),
              ),
            GlowButton(
              label: _step == 0
                  ? 'THAT’S ME'
                  : _step == 1
                      ? 'LOCK THE HANDLE'
                      : 'SEAL WITH FACE',
              onTap: _busy ? null : _next,
              busy: _busy,
            ),
          ],
        ),
      ),
    );
  }
}
