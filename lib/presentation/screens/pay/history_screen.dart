import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/illustrations.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/models.dart';
import '../../../data/models/spend_kinds.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  var _query = '';
  TxStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final txs = ref.watch(appStoreProvider).transactions.where((t) {
      final q = _query.toLowerCase();
      final hit = q.isEmpty ||
          t.vpa.toLowerCase().contains(q) ||
          t.payeeName.toLowerCase().contains(q) ||
          t.note.toLowerCase().contains(q) ||
          t.category.toLowerCase().contains(q) ||
          t.amountPaise.toString().contains(q);
      final st = _filter == null || t.status == _filter;
      return hit && st;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search merchant, note, amount',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _chip('All', null),
                _chip('Success', TxStatus.success),
                _chip('Pending', TxStatus.pending),
                _chip('Failed', TxStatus.failed),
              ],
            ),
          ),
          Expanded(
            child: txs.isEmpty
                ? const Center(
                    child: EmptyScene(
                      art: ZepArt.history,
                      message:
                          'Nothing here yet. Scan a QR to make your first pay.',
                    ),
                  )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: txs.length,
              itemBuilder: (context, i) {
                final tx = txs[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SurfaceCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => context.push('/history/${tx.id}'),
                      title: Text(tx.payeeName.isEmpty ? tx.vpa : tx.payeeName),
                      subtitle: Text(
                        '${SpendKinds.byId(tx.category).label} · ${tx.status.name} · ${DateFormat('d MMM, h:mm a').format(tx.createdAt)}',
                      ),
                      trailing: MoneyText(tx.amountPaise,
                          style: Theme.of(context).textTheme.titleMedium),
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

  Widget _chip(String label, TxStatus? status) {
    final on = _filter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: on,
        selectedColor: AppColors.hero.withValues(alpha: 0.25),
        onSelected: (_) => setState(() => _filter = status),
      ),
    );
  }
}
