import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/models.dart';

class SplitHomeScreen extends ConsumerWidget {
  const SplitHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(appStoreProvider).groups;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split'),
        actions: [
          IconButton(
            onPressed: () => _newGroup(context, ref),
            icon: const Icon(Icons.group_add_rounded),
          ),
        ],
      ),
      body: groups.isEmpty
          ? Center(
              child: Text('Trip, house, or 1-on-1. Add a group to start.',
                  style: Theme.of(context).textTheme.bodyMedium),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: groups.length,
              itemBuilder: (context, i) {
                final g = groups[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SurfaceCard(
                    onTap: () => context.push('/split/${g.id}'),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.surfaceHigh,
                          child: Text(g.name.characters.first.toUpperCase()),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g.name, style: Theme.of(context).textTheme.titleMedium),
                              Text('${g.kind} · ${g.members.length} people',
                                  style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textDim),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _newGroup(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    var kind = 'trip';
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'GROUP NAME')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['trip', 'house', 'pair']
                    .map((k) => ChoiceChip(
                          label: Text(k),
                          selected: kind == k,
                          onSelected: (_) => setSt(() => kind = k),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              HapticScale(
                onTap: () async {
                  final me = ref.read(appStoreProvider).profile;
                  final members = [
                    GroupMember(
                      id: 'me',
                      name: me?.name ?? 'You',
                      phone: me?.phone ?? '',
                      upiId: me?.upiId ?? '',
                    ),
                  ];
                  if (await FlutterContacts.requestPermission()) {
                    final contacts = await FlutterContacts.getContacts(withProperties: true);
                    for (final c in contacts.take(8)) {
                      if (c.phones.isEmpty) continue;
                      members.add(GroupMember(
                        id: c.id,
                        name: c.displayName,
                        phone: c.phones.first.number,
                      ));
                    }
                  }
                  await ref.read(appStoreProvider.notifier).upsertGroup(
                        SplitGroup(
                          id: AppStore.id(),
                          name: name.text.trim().isEmpty ? 'New group' : name.text.trim(),
                          kind: kind,
                          members: members,
                        ),
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.hero, borderRadius: BorderRadius.circular(14)),
                  child: const Text('CREATE GROUP'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
