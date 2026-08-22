import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/chrome.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/models.dart';

/// Compose a payment request — distinct route from the approve/pending list.
class RequestMoneyScreen extends ConsumerStatefulWidget {
  const RequestMoneyScreen({super.key});

  @override
  ConsumerState<RequestMoneyScreen> createState() => _RequestMoneyScreenState();
}

class _RequestMoneyScreenState extends ConsumerState<RequestMoneyScreen> {
  final _phone = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final rupees = double.tryParse(_amount.text.trim()) ?? 0;
    if (rupees <= 0 || _phone.text.trim().length < 10) return;
    final me = ref.read(appStoreProvider).sessionPhone ?? '';
    final profile = ref.read(appStoreProvider).profile;
    await ref.read(appStoreProvider.notifier).addRequest(
          PayRequest(
            id: AppStore.id(),
            fromPhone: me,
            fromName: profile?.name ?? '',
            toPhone: _phone.text.trim(),
            toVpa: profile?.upiId ?? '',
            amountPaise: (rupees * 100).round(),
            note: _note.text.trim(),
            status: RequestStatus.pending,
            createdAt: DateTime.now(),
          ),
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return ZepPage(
      title: 'Request money',
      subtitle: 'Ask someone to pay you — stored on this device',
      footer: GlowButton(label: 'SEND REQUEST', onTap: _send),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          TextField(
            controller: _phone,
            decoration: const InputDecoration(labelText: 'THEIR PHONE'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            decoration: const InputDecoration(labelText: 'AMOUNT (₹)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'NOTE'),
          ),
        ],
      ),
    );
  }
}
