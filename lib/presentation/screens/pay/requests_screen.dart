import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/models.dart';
import '../../../data/services/providers.dart';

class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(appStoreProvider).sessionPhone ?? '';
    final reqs = ref.watch(appStoreProvider).requests;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Requests'),
        actions: [
          IconButton(
            onPressed: () => _compose(context, ref),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: reqs.isEmpty
          ? const Center(child: Text('No pending requests'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: reqs.length,
              itemBuilder: (context, i) {
                final r = reqs[i];
                final incoming = r.toPhone == me;
                return SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(incoming ? r.fromName : 'You → ${r.toPhone}',
                          style: Theme.of(context).textTheme.titleMedium),
                      MoneyText(r.amountPaise, style: Theme.of(context).textTheme.headlineMedium),
                      Text(r.note, style: Theme.of(context).textTheme.bodyMedium),
                      Text(r.status.name.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
                      if (incoming && r.status == RequestStatus.pending) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => ref
                                  .read(appStoreProvider.notifier)
                                  .updateRequest(r.id, RequestStatus.declined),
                              child: const Text('Decline', style: TextStyle(color: AppColors.danger)),
                            ),
                            const Spacer(),
                            HapticScale(
                              onTap: () {
                                ref.read(paymentDraftProvider.notifier).state = PaymentDraft(
                                  vpa: r.fromPhone.contains('@') ? r.fromPhone : '${r.fromPhone}@upi',
                                  amountPaise: r.amountPaise,
                                  payeeName: r.fromName,
                                  note: r.note,
                                  source: 'request',
                                );
                                context.push('/face');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.hero,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text('PAY'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _compose(BuildContext context, WidgetRef ref) async {
    final to = TextEditingController();
    final amt = TextEditingController();
    final note = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: to, decoration: const InputDecoration(labelText: 'TO PHONE')),
            const SizedBox(height: 8),
            TextField(controller: amt, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'AMOUNT')),
            const SizedBox(height: 8),
            TextField(controller: note, decoration: const InputDecoration(labelText: 'NOTE')),
            const SizedBox(height: 12),
            HapticScale(
              onTap: () async {
                final rupees = double.tryParse(amt.text) ?? 0;
                final me = ref.read(appStoreProvider);
                await ref.read(appStoreProvider.notifier).addRequest(
                      PayRequest(
                        id: AppStore.id(),
                        fromPhone: me.sessionPhone ?? '',
                        fromName: me.profile?.name ?? 'You',
                        toPhone: to.text.trim(),
                        amountPaise: (rupees * 100).round(),
                        note: note.text.trim(),
                        status: RequestStatus.pending,
                        createdAt: DateTime.now(),
                      ),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Container(
                width: double.infinity,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.hero, borderRadius: BorderRadius.circular(14)),
                child: const Text('SEND REQUEST'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
