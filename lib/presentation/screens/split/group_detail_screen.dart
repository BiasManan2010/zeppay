import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/models.dart';
import '../../../data/services/csv_export_service.dart';
import '../../../data/services/providers.dart';
import '../../../data/services/split_math.dart';
import '../../widgets/contact_picker.dart';

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
    final settlements = app.settlements
        .where((s) => s.groupId == groupId)
        .toList();
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
            tooltip: 'Add people',
            onPressed: () async {
              final extra = await pickGroupMembers(context);
              if (extra.isEmpty) return;
              final ids = group.members.map((m) => m.id).toSet();
              await ref.read(appStoreProvider.notifier).upsertGroup(
                    group.copyWith(
                      members: [
                        ...group.members,
                        ...extra.where((m) => !ids.contains(m.id)),
                      ],
                    ),
                  );
            },
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
          IconButton(
            tooltip: 'Export CSV',
            onPressed: () async {
              final csv = CsvExportService().exportGroup(
                group: group,
                expenses: expenses,
                settlements: settlements,
              );
              final dir = await getTemporaryDirectory();
              final safe = group.name.replaceAll(RegExp(r'[^\w]+'), '_');
              final file = File('${dir.path}/$safe.csv');
              await file.writeAsString(csv);
              await Share.shareXFiles([
                XFile(file.path, mimeType: 'text/csv'),
              ], text: '${group.name} ledger');
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
          Text('PEOPLE', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          ...group.members.map((m) {
            final share = group.defaultShares[m.id] ?? m.defaultShare;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(m.name),
              subtitle: Text(
                [
                  if (m.phone.isNotEmpty) m.phone,
                  'share $share',
                ].join(' · '),
              ),
              trailing: m.id == 'me'
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, color: AppColors.danger),
                      onPressed: () {
                        ref.read(appStoreProvider.notifier).upsertGroup(
                              group.copyWith(
                                members: group.members
                                    .where((x) => x.id != m.id)
                                    .toList(),
                              ),
                            );
                      },
                    ),
              onTap: () => _editShare(context, ref, group, m),
            );
          }),
          const SizedBox(height: 18),
          Text('BALANCES', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          if (simplified.isEmpty)
            Text('Settled up.', style: Theme.of(context).textTheme.bodyMedium)
          else
            ...simplified.map((e) {
              final from =
                  group.members
                      .where((m) => m.id == e.from)
                      .firstOrNull
                      ?.name ??
                  e.from;
              final to =
                  group.members.where((m) => m.id == e.to).firstOrNull?.name ??
                  e.to;
              return SurfaceCard(
                child: Row(
                  children: [
                    Expanded(child: Text('$from owes $to')),
                    MoneyText(e.amount),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        final payee = group.members
                            .where((m) => m.id == e.to)
                            .firstOrNull;
                        startPayment(
                          ref,
                          vpa: (payee?.upiId.isNotEmpty == true)
                              ? payee!.upiId
                              : '${payee?.phone ?? ''}@upi',
                          amountPaise: e.amount,
                          payeeName: to,
                          note: 'Settle ${group.name}',
                          source: 'split',
                          settleGroupId: groupId,
                          settleFromId: e.from,
                          settleToId: e.to,
                        );
                        context.push('/face');
                      },
                      child: const Text('Settle'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await ref
                            .read(appStoreProvider.notifier)
                            .addSettlement(
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
              onTap: () => context.push('/split/$groupId/expense/${e.id}'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editShare(
    BuildContext context,
    WidgetRef ref,
    SplitGroup group,
    GroupMember member,
  ) async {
    final ctrl = TextEditingController(
      text: '${group.defaultShares[member.id] ?? member.defaultShare}',
    );
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Default share for ${member.name}',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'SHARES'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                final v = double.tryParse(ctrl.text) ?? 1;
                final next = Map<String, double>.from(group.defaultShares)
                  ..[member.id] = v;
                final members = group.members
                    .map((m) => m.id == member.id ? m.copyWith(defaultShare: v) : m)
                    .toList();
                ref
                    .read(appStoreProvider.notifier)
                    .upsertGroup(group.copyWith(members: members, defaultShares: next));
                Navigator.pop(ctx);
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }
}
