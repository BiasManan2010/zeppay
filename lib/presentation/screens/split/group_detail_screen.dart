import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/models.dart';
import '../../../data/services/csv_export_service.dart';
import '../../../data/services/providers.dart';
import '../../../data/services/split_math.dart';

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStoreProvider);
    final group = app.groups.where((g) => g.id == groupId).firstOrNull;
    if (group == null) {
      return const Scaffold(body: Center(child: Text('Group missing')));
    }
    final expenses = app.expenses.where((e) => e.groupId == groupId).toList();
    final settlements = app.settlements.where((s) => s.groupId == groupId).toList();
    final simplified = SplitMath.simplify(
      members: group.members,
      expenses: expenses,
      settlements: settlements,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: () async {
              final file = await CsvExportService().exportGroup(
                group: group,
                expenses: expenses,
                settlements: settlements,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saved ${file.path}')),
                );
              }
            },
            icon: const Icon(Icons.ios_share),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.hero,
        onPressed: () => context.push('/split/$groupId/add'),
        label: const Text('Add bill'),
        icon: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Text('BALANCES', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          if (simplified.isEmpty)
            Text('Settled up.', style: Theme.of(context).textTheme.bodyMedium)
          else
            ...simplified.map((e) {
              final from = group.members.where((m) => m.id == e.from).firstOrNull?.name ?? e.from;
              final to = group.members.where((m) => m.id == e.to).firstOrNull?.name ?? e.to;
              return SurfaceCard(
                child: Row(
                  children: [
                    Expanded(child: Text('$from owes $to')),
                    MoneyText(e.amount),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        final payee = group.members.where((m) => m.id == e.to).firstOrNull;
                        ref.read(paymentDraftProvider.notifier).state = PaymentDraft(
                          vpa: (payee?.upiId.isNotEmpty == true) ? payee!.upiId : '${payee?.phone ?? ''}@upi',
                          amountPaise: e.amount,
                          payeeName: to,
                          note: 'Settle ${group.name}',
                          source: 'split',
                        );
                        context.push('/face');
                      },
                      child: const Text('Settle'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await ref.read(appStoreProvider.notifier).addSettlement(
                              Settlement(
                                id: AppStore.id(),
                                groupId: groupId,
                                fromId: e.from,
                                toId: e.to,
                                amountPaise: e.amount,
                                createdAt: DateTime.now(),
                                method: 'cash',
                              ),
                            );
                      },
                      child: const Text('Cash'),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 18),
          Text('EXPENSES', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          ...expenses.map(
            (e) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(e.title),
              subtitle: Text('${e.category} · ${e.currency} · ${e.mode.name}'),
              trailing: MoneyText(e.amountPaise),
            ),
          ),
        ],
      ),
    );
  }
}
