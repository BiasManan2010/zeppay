import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../data/models/models.dart';
import '../../../data/services/providers.dart';

class PayFriendsScreen extends ConsumerStatefulWidget {
  const PayFriendsScreen({super.key});

  @override
  ConsumerState<PayFriendsScreen> createState() => _PayFriendsScreenState();
}

class _PayFriendsScreenState extends ConsumerState<PayFriendsScreen> {
  final _vpa = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    final draft = ref.read(paymentDraftProvider);
    if (draft != null) {
      _vpa.text = draft.vpa;
      if (draft.amountPaise > 0) {
        _amount.text = (draft.amountPaise / 100).toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _vpa.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _pay() {
    final vpa = _vpa.text.trim();
    final rupees = double.tryParse(_amount.text.trim()) ?? 0;
    if (!vpa.contains('@') && !RegExp(r'^\d{10}$').hasMatch(vpa.replaceAll('+91', ''))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a UPI ID or 10-digit number')),
      );
      return;
    }
    if (rupees <= 0) return;
    final resolved = vpa.contains('@') ? vpa : '$vpa@upi';
    ref.read(paymentDraftProvider.notifier).state = PaymentDraft(
      vpa: resolved,
      amountPaise: (rupees * 100).round(),
      payeeName: vpa,
      note: _note.text.trim(),
      source: 'friends',
    );
    context.push('/face');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pay friends')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _vpa,
            decoration: const InputDecoration(
              labelText: 'UPI ID OR PHONE',
              hintText: 'friend@okicici',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'AMOUNT (₹)'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _note, decoration: const InputDecoration(labelText: 'NOTE')),
          const SizedBox(height: 24),
          HapticScale(
            onTap: _pay,
            child: Container(
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.hero,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text('PAY',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.base)),
            ),
          ),
          const SizedBox(height: 12),
          HapticScale(
            onTap: () => context.push('/scan'),
            child: const Center(child: Text('Or scan their QR')),
          ),
        ],
      ),
    );
  }
}
