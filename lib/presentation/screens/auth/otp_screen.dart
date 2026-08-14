import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chrome.dart';
import '../../../data/local/app_store.dart';
import '../../../data/services/providers.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _code = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final phone = ref.read(pendingPhoneProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await ref.read(otpServiceProvider).check(phone, _code.text.trim());
    if (!ok) {
      setState(() {
        _busy = false;
        _error = 'That code did not match.';
      });
      return;
    }
    await ref.read(appStoreProvider.notifier).login(phone);
    if (mounted) context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final phone = ref.watch(pendingPhoneProvider);
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.go('/login'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter the code', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 8),
            Text('Sent to $phone', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 28),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(
                letterSpacing: 12,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(counterText: '', hintText: '••••••'),
            ),
            if (_error != null) Text(_error!, style: const TextStyle(color: AppColors.danger)),
            const Spacer(),
            GlowButton(label: 'VERIFY', onTap: _busy ? null : _verify, busy: _busy),
          ],
        ),
      ),
    );
  }
}
