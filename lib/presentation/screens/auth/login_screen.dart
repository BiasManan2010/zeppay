import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
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
    final raw = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (raw.length < 10) {
      setState(() => _error = 'Enter a valid 10-digit mobile number');
      return;
    }
    final phone = raw.length == 10 ? '+91$raw' : '+$raw';
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(otpServiceProvider).send(phone);
      ref.read(pendingPhoneProvider.notifier).state = phone;
      if (mounted) context.go('/otp');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BoltCheck(size: 72),
              const SizedBox(height: 28),
              Text('Pay even when\nthe internet dies.',
                  style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 10),
              Text(
                'Phone number in. One OTP. Then you scan and go.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  labelText: 'MOBILE NUMBER',
                  hintText: '98765 43210',
                  prefixText: '+91  ',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 18),
              GlowButton(label: 'SEND OTP', onTap: _busy ? null : _send, busy: _busy),
              const SizedBox(height: 12),
              Text(
                'Dev OTP is 123456 until Twilio is wired.',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
        ),
      ),
    );
  }
}
