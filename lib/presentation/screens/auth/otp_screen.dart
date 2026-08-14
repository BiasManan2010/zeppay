import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  final _focus = FocusNode();
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _code.addListener(() {
      setState(() {});
      if (_code.text.length == 6 && !_busy) {
        _verify();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final phone = ref.read(pendingPhoneProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok =
        await ref.read(otpServiceProvider).check(phone, _code.text.trim());
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
    final digits = _code.text.padRight(6);
    return AuthBackdrop(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text('Enter the code',
                style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 8),
            Text(
              'Sent to $phone',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => _focus.requestFocus(),
              child: Row(
                children: [
                  for (var i = 0; i < 6; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: i == _code.text.length
                                ? AppColors.hero
                                : AppColors.surfaceBorder,
                            width: i == _code.text.length ? 1.6 : 1,
                          ),
                        ),
                        child: Text(
                          digits[i] == ' ' ? '' : digits[i],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Opacity(
              opacity: 0,
              child: SizedBox(
                height: 1,
                child: TextField(
                  controller: _code,
                  focusNode: _focus,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(counterText: ''),
                ),
              ),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            const Spacer(),
            GlowButton(
              label: 'VERIFY',
              onTap: _busy || _code.text.length < 6 ? null : _verify,
              busy: _busy,
            ),
          ],
        ).animate().fadeIn(duration: 350.ms),
      ),
    );
  }
}
