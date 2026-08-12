import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/models.dart';
import '../../../data/services/providers.dart';

class AutopayScreen extends ConsumerWidget {
  const AutopayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mandates = ref.watch(appStoreProvider).mandates;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autopay'),
        actions: [
          IconButton(onPressed: () => _edit(context, ref, null), icon: const Icon(Icons.add)),
        ],
      ),
      body: mandates.isEmpty
          ? const Center(child: Text('No mandates yet'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: mandates.length,
              itemBuilder: (context, i) {
                final m = mandates[i];
                return SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(m.payee, style: Theme.of(context).textTheme.titleMedium)),
                          Switch(
                            value: m.active,
                            activeTrackColor: AppColors.hero,
                            onChanged: (v) => ref.read(appStoreProvider.notifier).upsertMandate(m.copyWith(active: v)),
                          ),
                        ],
                      ),
                      MoneyText(m.amountPaise, style: Theme.of(context).textTheme.headlineMedium),
                      Text(
                        '${m.frequency.name} · limit ₹${(m.limitPaise / 100).toStringAsFixed(0)} · next ${DateFormat('d MMM').format(m.nextRun)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(paymentDraftProvider.notifier).state = PaymentDraft(
                            vpa: m.vpa,
                            amountPaise: m.amountPaise,
                            payeeName: m.payee,
                            note: 'Autopay',
                            source: 'autopay',
                          );
                          context.push('/face');
                        },
                        child: const Text('Run now'),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, AutopayMandate? existing) async {
    final payee = TextEditingController(text: existing?.payee);
    final vpa = TextEditingController(text: existing?.vpa);
    final amt = TextEditingController(
      text: existing == null ? '' : (existing.amountPaise / 100).toStringAsFixed(0),
    );
    final limit = TextEditingController(
      text: existing == null ? '' : (existing.limitPaise / 100).toStringAsFixed(0),
    );
    var freq = existing?.frequency ?? AutopayFrequency.monthly;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: payee, decoration: const InputDecoration(labelText: 'PAYEE')),
              const SizedBox(height: 8),
              TextField(controller: vpa, decoration: const InputDecoration(labelText: 'UPI ID')),
              const SizedBox(height: 8),
              TextField(controller: amt, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'AMOUNT')),
              const SizedBox(height: 8),
              TextField(controller: limit, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'LIMIT')),
              DropdownButton<AutopayFrequency>(
                value: freq,
                items: AutopayFrequency.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                    .toList(),
                onChanged: (v) => setSt(() => freq = v ?? freq),
              ),
              HapticScale(
                onTap: () async {
                  final a = ((double.tryParse(amt.text) ?? 0) * 100).round();
                  final l = ((double.tryParse(limit.text) ?? a) * 100).round();
                  await ref.read(appStoreProvider.notifier).upsertMandate(
                        AutopayMandate(
                          id: existing?.id ?? AppStore.id(),
                          payee: payee.text.trim(),
                          vpa: vpa.text.trim(),
                          amountPaise: a,
                          frequency: freq,
                          nextRun: DateTime.now().add(const Duration(days: 1)),
                          limitPaise: l,
                        ),
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.hero, borderRadius: BorderRadius.circular(14)),
                  child: const Text('SAVE MANDATE'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
