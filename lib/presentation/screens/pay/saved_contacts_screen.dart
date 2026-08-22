import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/chrome.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/models.dart';
import '../../../data/services/providers.dart';

/// Local payees saved from successful payments — not the device address book.
class SavedContactsScreen extends ConsumerStatefulWidget {
  const SavedContactsScreen({super.key});

  @override
  ConsumerState<SavedContactsScreen> createState() =>
      _SavedContactsScreenState();
}

class _SavedContactsScreenState extends ConsumerState<SavedContactsScreen> {
  var _query = '';

  List<SavedPayee> _sorted(List<SavedPayee> all) {
    final q = _query.trim().toLowerCase();
    final filtered = all.where((p) {
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.vpa.toLowerCase().contains(q) ||
          p.phone.contains(q);
    }).toList();
    final fav = filtered.where((p) => p.favorite).toList()
      ..sort((a, b) => _sortKey(a).compareTo(_sortKey(b)));
    final rest = filtered.where((p) => !p.favorite).toList()
      ..sort((a, b) => _sortKey(a).compareTo(_sortKey(b)));
    return [...fav, ...rest];
  }

  String _sortKey(SavedPayee p) =>
      (p.name.trim().isNotEmpty ? p.name : p.vpa).toLowerCase();

  void _pay(SavedPayee p) {
    startPayment(
      ref,
      vpa: p.vpa,
      amountPaise: 0,
      payeeName: p.name,
      source: 'saved_contact',
    );
    context.push('/pay/amount');
  }

  @override
  Widget build(BuildContext context) {
    final payees = ref.watch(appStoreProvider).payees;
    final list = _sorted(payees);
    final fmt = DateFormat('d MMM');

    return ZepPage(
      title: 'Contacts',
      subtitle: 'Saved from successful pays on this device',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search name or UPI ID',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text(
                      'No saved contacts yet.\nComplete a payment to auto-save.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final p = list[i];
                      final label =
                          p.name.trim().isNotEmpty ? p.name.trim() : p.vpa;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SurfaceCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            onTap: () => _pay(p),
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.accent.withValues(alpha: 0.16),
                              child: Text(
                                label.characters.first.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.heroDeep,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            title: Text(label),
                            subtitle: Text(
                              [
                                p.vpa,
                                if (p.lastPaidAt != null)
                                  'Last paid ${fmt.format(p.lastPaidAt!)}',
                              ].join(' · '),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                p.favorite
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: p.favorite
                                    ? AppColors.warning
                                    : AppColors.textMuted,
                              ),
                              onPressed: () => ref
                                  .read(appStoreProvider.notifier)
                                  .toggleFavorite(p.vpa, name: p.name),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
