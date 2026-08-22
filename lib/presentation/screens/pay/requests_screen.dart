import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/chrome.dart';
import '../../../core/widgets/illustrations.dart';
import '../../../core/widgets/zep_components.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/models.dart';
import '../../../data/services/providers.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(appStoreProvider).sessionPhone ?? '';
    final reqs = ref.watch(appStoreProvider).requests;
    final pending = reqs.where((r) => r.status == RequestStatus.pending).toList();
    final done = reqs
        .where((r) => r.status != RequestStatus.pending)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final shown = _tab == 0 ? pending : done;
    final fmt = DateFormat('d MMM · h:mm a');

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Approve to pay'),
        actions: [
          IconButton(
            onPressed: () => _compose(context, ref),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _TabChip(
                  label: 'Pending',
                  count: pending.length,
                  selected: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                const SizedBox(width: 8),
                _TabChip(
                  label: 'Completed',
                  selected: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
              ],
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? const Center(
                    child: EmptyScene(
                      art: ZepArt.emptyRequest,
                      message: 'No requests here',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: shown.length,
                    itemBuilder: (context, i) {
                      final r = shown[i];
                      final incoming = r.toPhone == me;
                      final today = DateTime.now();
                      final isToday = r.createdAt.year == today.year &&
                          r.createdAt.month == today.month &&
                          r.createdAt.day == today.day;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (i == 0 ||
                              !_sameDay(shown[i - 1].createdAt, r.createdAt))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8, top: 8),
                              child: Text(
                                isToday
                                    ? 'Today'
                                    : DateFormat('EEEE, d MMM')
                                        .format(r.createdAt),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ),
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: _statusColor(r.status)
                                            .withValues(alpha: 0.15),
                                        child: Icon(
                                          _statusIcon(r.status),
                                          color: _statusColor(r.status),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              incoming
                                                  ? (r.fromName.isEmpty
                                                      ? r.fromPhone
                                                      : r.fromName)
                                                  : 'You → ${r.toPhone}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                            Text(
                                              fmt.format(r.createdAt),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '₹${(r.amountPaise / 100).toStringAsFixed(0)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ],
                                  ),
                                  if (r.note.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(r.note),
                                  ],
                                  if (incoming &&
                                      r.status == RequestStatus.pending) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () => ref
                                                .read(appStoreProvider.notifier)
                                                .updateRequest(
                                                  r.id,
                                                  RequestStatus.declined,
                                                ),
                                            child: const Text('Decline'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: FilledButton(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: AppColors.accent,
                                            ),
                                            onPressed: () {
                                              startPayment(
                                                ref,
                                                vpa: r.toVpa.contains('@')
                                                    ? r.toVpa
                                                    : (r.fromPhone.contains('@')
                                                        ? r.fromPhone
                                                        : '${r.fromPhone}@upi'),
                                                amountPaise: r.amountPaise,
                                                payeeName: r.fromName,
                                                note: r.note,
                                                requestId: r.id,
                                              );
                                              context.push('/pay/amount');
                                            },
                                            child: Text(
                                              'Pay ₹${(r.amountPaise / 100).toStringAsFixed(0)}',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Color _statusColor(RequestStatus s) => switch (s) {
        RequestStatus.pending => AppColors.accent,
        RequestStatus.paid => AppColors.success,
        RequestStatus.declined => AppColors.danger,
        RequestStatus.accepted => AppColors.success,
      };

  IconData _statusIcon(RequestStatus s) => switch (s) {
        RequestStatus.pending => Icons.schedule_rounded,
        RequestStatus.paid => Icons.check_circle_outline,
        RequestStatus.declined => Icons.cancel_outlined,
        RequestStatus.accepted => Icons.check,
      };

  Future<void> _compose(BuildContext context, WidgetRef ref) async {
    final to = TextEditingController();
    final amt = TextEditingController();
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: to,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: amt,
              decoration: const InputDecoration(labelText: 'Amount (₹)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: note,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final rupees = double.tryParse(amt.text) ?? 0;
    if (rupees <= 0 || to.text.trim().length < 10) return;
    final me = ref.read(appStoreProvider).sessionPhone ?? '';
    final profile = ref.read(appStoreProvider).profile;
    await ref.read(appStoreProvider.notifier).addRequest(
          PayRequest(
            id: AppStore.id(),
            fromPhone: me,
            toPhone: to.text.trim(),
            amountPaise: (rupees * 100).round(),
            status: RequestStatus.pending,
            createdAt: DateTime.now(),
            note: note.text.trim(),
            fromName: profile?.name ?? '',
            toVpa: profile?.upiId ?? '',
          ),
        );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          count != null && count! > 0 ? '$label ($count)' : label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.accent : AppColors.textOnCreamMuted,
          ),
        ),
      ),
    );
  }
}
