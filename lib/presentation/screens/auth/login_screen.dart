import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chrome.dart';
import '../../../data/services/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    var raw = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (raw.startsWith('91') && raw.length >= 12) {
      raw = raw.substring(raw.length - 10);
    }
    if (raw.length != 10) {
      setState(() => _error = 'Enter a valid 10-digit mobile number');
      return;
    }
    final phone = '+91$raw';
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(otpServiceProvider).send(phone);
      ref.read(pendingPhoneProvider.notifier).state = phone;
      if (mounted) context.go('/otp');
    } catch (e) {
      setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackdrop(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: BrandMark(size: 128)),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'ZEPPAY',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.white,
                  letterSpacing: 7,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Your number.\nThen you scan.',
              style: Theme.of(
                context,
              ).textTheme.displayMedium?.copyWith(height: 1.12),
            ),
            const SizedBox(height: 10),
            Text(
              'OTP is sent to the number you type — each person uses their own phone. Twilio trial only delivers to Verified Caller IDs until you upgrade.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const Spacer(),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MOBILE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.hero,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                    decoration: const InputDecoration(
                      hintText: '98765 43210',
                      prefixText: '+91  ',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlowButton(
              label: 'SEND OTP',
              onTap: _busy ? null : _send,
              busy: _busy,
            ),
            const SizedBox(height: 12),
            Center(
              child: ref
                  .watch(otpLiveProvider)
                  .when(
                    data: (live) => Text(
                      live
                          ? 'We’ll text a 6-digit code to this number.'
                          : 'No OTP URL yet — use 123456, or tap Twilio setup.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
            ),
            TextButton(
              onPressed: () => context.push('/verify-setup'),
              child: const Text('Twilio setup'),
            ),
          ],
        ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.04, end: 0),
      ),
    );
  }
}
