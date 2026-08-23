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

enum _DateFilter { all, week, month, custom }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  var _query = '';
  TxStatus? _statusFilter;
  _DateFilter _dateFilter = _DateFilter.all;
  DateTimeRange? _customRange;

  bool _inDateRange(DateTime createdAt) {
    final now = DateTime.now();
    switch (_dateFilter) {
      case _DateFilter.all:
        return true;
      case _DateFilter.week:
        final start = now.subtract(Duration(days: now.weekday - 1));
        final weekStart =
            DateTime(start.year, start.month, start.day);
        return !createdAt.isBefore(weekStart);
      case _DateFilter.month:
        final monthStart = DateTime(now.year, now.month);
        return !createdAt.isBefore(monthStart);
      case _DateFilter.custom:
        if (_customRange == null) return true;
        final start = DateTime(
          _customRange!.start.year,
          _customRange!.start.month,
          _customRange!.start.day,
        );
        final end = DateTime(
          _customRange!.end.year,
          _customRange!.end.month,
          _customRange!.end.day,
          23,
          59,
          59,
        );
        return !createdAt.isBefore(start) && !createdAt.isAfter(end);
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
    );
    if (range == null || !mounted) return;
    setState(() {
      _customRange = range;
      _dateFilter = _DateFilter.custom;
    });
  }

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
      final st = _statusFilter == null || t.status == _statusFilter;
      return hit && st && _inDateRange(t.createdAt);
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
                hintText: 'Search name, UPI ID, note, amount',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _statusChip('All', null),
                _statusChip('Success', TxStatus.success),
                _statusChip('Pending', TxStatus.pending),
                _statusChip('Failed', TxStatus.failed),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _dateChip('All time', _DateFilter.all),
                _dateChip('This week', _DateFilter.week),
                _dateChip('This month', _DateFilter.month),
                ActionChip(
                  label: Text(
                    _dateFilter == _DateFilter.custom && _customRange != null
                        ? '${DateFormat('d MMM').format(_customRange!.start)} – '
                            '${DateFormat('d MMM').format(_customRange!.end)}'
                        : 'Custom',
                  ),
                  onPressed: _pickCustomRange,
                ),
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: txs.length,
                    itemBuilder: (context, i) {
                      final tx = txs[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SurfaceCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            onTap: () => context.push('/history/${tx.id}'),
                            leading: Icon(
                              SpendKinds.byId(tx.category).icon,
                              color: AppColors.accent,
                            ),
                            title: Text(
                              tx.payeeName.isEmpty ? tx.vpa : tx.payeeName,
                            ),
                            subtitle: Text(
                              '${SpendKinds.byId(tx.category).label} · '
                              '${tx.status.name} · '
                              '${DateFormat('d MMM, h:mm a').format(tx.createdAt)}',
                            ),
                            trailing: MoneyText(
                              tx.amountPaise,
                              style: Theme.of(context).textTheme.titleMedium,
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

  Widget _statusChip(String label, TxStatus? status) {
    final on = _statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: on,
        selectedColor: AppColors.hero.withValues(alpha: 0.25),
        onSelected: (_) => setState(() => _statusFilter = status),
      ),
    );
  }

  Widget _dateChip(String label, _DateFilter filter) {
    final on = _dateFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: on,
        selectedColor: AppColors.accent.withValues(alpha: 0.2),
        onSelected: (_) => setState(() => _dateFilter = filter),
      ),
    );
  }
}
