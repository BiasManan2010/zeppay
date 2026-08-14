import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/brand.dart';
import '../../../core/widgets/chrome.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/models.dart';
import '../../../data/services/providers.dart';
import '../../../data/services/split_math.dart';

class SplitBillScreen extends ConsumerStatefulWidget {
  const SplitBillScreen({super.key});

  @override
  ConsumerState<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends ConsumerState<SplitBillScreen> {
  String? _groupId;
  final _title = TextEditingController();
  final _amount = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(appStoreProvider).groups;
    return ZepPage(
      title: 'Split a bill',
      subtitle:
          'Equal split across the group. Open a group for exact / percent / OCR splits.',
      footer: GlowButton(
        label: 'SPLIT EQUALLY',
        onTap: () async {
          final id = _groupId ?? (groups.isNotEmpty ? groups.first.id : null);
          if (id == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Create a group first')),
            );
            return;
          }
          final group = groups.firstWhere((g) => g.id == id);
          final rupees = double.tryParse(_amount.text) ?? 0;
          if (rupees <= 0 || _title.text.trim().isEmpty) return;
          final total = (rupees * 100).round();
          final shares = SplitMath.compute(
            mode: SplitMode.equal,
            totalPaise: total,
            members: group.members,
          );
          await ref
              .read(appStoreProvider.notifier)
              .addExpense(
                Expense(
                  id: AppStore.id(),
                  groupId: id,
                  title: _title.text.trim(),
                  amountPaise: total,
                  createdAt: DateTime.now(),
                  payerIds: const ['me'],
                  shares: shares,
                ),
              );
          if (context.mounted) context.push('/split/$id');
        },
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          if (groups.isEmpty)
            const Text('No groups yet. Open My Groups to create one.')
          else
            DropdownButtonFormField<String>(
              initialValue: _groupId ?? groups.first.id,
              items: groups
                  .map(
                    (g) => DropdownMenuItem(value: g.id, child: Text(g.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _groupId = v),
              decoration: const InputDecoration(labelText: 'GROUP'),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'WHAT FOR'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'TOTAL (₹)'),
          ),
        ],
      ),
    );
  }
}

class SettleHubScreen extends ConsumerWidget {
  const SettleHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStoreProvider);
    final rows = <Widget>[];
    for (final g in app.groups) {
      final edges = SplitMath.simplify(
        members: g.members,
        expenses: app.expenses.where((e) => e.groupId == g.id).toList(),
        settlements: app.settlements.where((s) => s.groupId == g.id).toList(),
      );
      if (edges.isEmpty) continue;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 8),
          child: Text(g.name, style: Theme.of(context).textTheme.titleMedium),
        ),
      );
      for (final e in edges) {
        final from =
            g.members.where((m) => m.id == e.from).firstOrNull?.name ?? e.from;
        final to =
            g.members.where((m) => m.id == e.to).firstOrNull?.name ?? e.to;
        final payee = g.members.where((m) => m.id == e.to).firstOrNull;
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SurfaceCard(
              child: Row(
                children: [
                  Expanded(child: Text('$from owes $to')),
                  MoneyText(e.amount),
                  TextButton(
                      onPressed: () {
                        startPayment(
                          ref,
                          vpa: payee?.upiId.isNotEmpty == true
                              ? payee!.upiId
                              : '${payee?.phone}@upi',
                          amountPaise: e.amount,
                          payeeName: to,
                          note: 'Settle ${g.name}',
                          source: 'settle',
                          settleGroupId: g.id,
                          settleFromId: e.from,
                          settleToId: e.to,
                        );
                        context.push('/pay/amount');
                      },
                    child: const Text('Settle'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
    return ZepPage(
      title: 'Settle up',
      subtitle:
          'Every open debt across groups. Settle uses the same biometric + rail flow.',
      child: rows.isEmpty
          ? const Center(child: Text('Nothing to settle.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: rows,
            ),
    );
  }
}

class SplitActivityScreen extends ConsumerWidget {
  const SplitActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStoreProvider);
    final items = [...app.expenses]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ZepPage(
      title: 'Split activity',
      subtitle: 'Bills logged in groups — not UPI history.',
      child: items.isEmpty
          ? const Center(child: Text('No bills yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final e = items[i];
                final g = app.groups
                    .where((x) => x.id == e.groupId)
                    .firstOrNull;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SurfaceCard(
                    onTap: () => context.push('/split/${e.groupId}'),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '${g?.name ?? 'Group'} · ${DateFormat('d MMM').format(e.createdAt)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        MoneyText(
                          e.amountPaise,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
