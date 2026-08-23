import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/media_image.dart';
import '../../../core/platform.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/chrome.dart';
import '../../../core/widgets/illustrations.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/models.dart';
import '../../../data/services/providers.dart';
import '../../../data/services/rail_engine.dart';
import '../../../data/services/receipt_share.dart';
import '../home/home_shell.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = isWebApp
        ? const [
            (
              'Scan or pick a payee',
              'QR, mobile, UPI ID, or bank. Amount stays on this phone.',
            ),
            (
              'Phone dialer opens',
              'UPI ID is copied. *99*1*3 opens in Phone — paste, amount, PIN.',
            ),
            (
              'You report the USSD result',
              'What did *99# show? SUCCESS / FAILED / CANCELLED / PENDING — that is the record.',
            ),
            (
              'History stays honest',
              'We never mark paid without your tap. Check bank SMS if unsure.',
            ),
          ]
        : const [
            (
              'Scan or pick a payee',
              'QR, mobile, UPI ID, contacts, or bank. Amount stays on this phone.',
            ),
            (
              'Face or device lock',
              'Every payment needs biometric or PIN. Nothing dials until you confirm.',
            ),
            (
              '*99# or 123PAY',
              'Android picks USSD when the SIM supports it, else Jio/4G uses 123PAY IVR. iOS opens UPI instead.',
            ),
            (
              'UPI PIN in the dialer',
              'That PIN never touches Zep Pay. After the call ends we ask if it landed.',
            ),
            (
              'History stays honest',
              'Yes / pending / failed is your call. We do not invent a success.',
            ),
          ];
    return ZepPage(
      title: 'How Zep Pay works',
      subtitle: isWebApp
          ? 'iPhone PWA: scan, *99*1*3 in Phone, then you confirm.'
          : 'Offline rails, then the everyday layer on top.',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SurfaceCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.hero.withValues(alpha: 0.16),
                      foregroundColor: AppColors.hero,
                      child: Text('${i + 1}'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i].$1,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            steps[i].$2,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (supportsOfflineRails)
            GlowButton(
              label: 'OFFLINE RAILS',
              onTap: () => context.push('/offline'),
            ),
        ],
      ),
    );
  }
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  var _q = '';

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appStoreProvider);
    final q = _q.trim().toLowerCase();
    final txs = q.isEmpty
        ? const <TxRecord>[]
        : app.transactions
              .where(
                (t) =>
                    t.vpa.toLowerCase().contains(q) ||
                    t.payeeName.toLowerCase().contains(q) ||
                    t.note.toLowerCase().contains(q) ||
                    (t.amountPaise / 100).toString().contains(q),
              )
              .toList();
    final bills = q.isEmpty
        ? const <Expense>[]
        : app.expenses
              .where(
                (e) =>
                    e.title.toLowerCase().contains(q) ||
                    e.note.toLowerCase().contains(q) ||
                    e.category.toLowerCase().contains(q),
              )
              .toList();
    return ZepPage(
      title: 'Search',
      subtitle: 'Payments, notes, and split bills on this device.',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _q = v),
              decoration: const InputDecoration(
                hintText: 'Merchant, VPA, bill, amount',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: q.isEmpty
                ? const Center(
                    child: EmptyScene(
                      art: ZepArt.history,
                      message: 'Type to search everything local.',
                      size: 140,
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
                      if (txs.isEmpty && bills.isEmpty)
                        const Text('Nothing matched.'),
                      ...txs.map(
                        (t) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: TxStatusDot(t.status),
                          title: Text(
                            t.payeeName.isEmpty ? t.vpa : t.payeeName,
                          ),
                          subtitle: Text(t.vpa),
                          trailing: MoneyText(t.amountPaise),
                          onTap: () => context.push('/history/${t.id}'),
                        ),
                      ),
                      ...bills.map(
                        (e) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.receipt_long_rounded),
                          title: Text(e.title),
                          subtitle: Text(e.category),
                          trailing: MoneyText(e.amountPaise),
                          onTap: () =>
                              context.push('/split/${e.groupId}/expense/${e.id}'),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class TxDetailScreen extends ConsumerWidget {
  const TxDetailScreen({super.key, required this.txId});
  final String txId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tx = ref
        .watch(appStoreProvider)
        .transactions
        .where((t) => t.id == txId)
        .firstOrNull;
    if (tx == null) {
      return const ZepPage(
        title: 'Payment',
        child: Center(child: Text('This payment is gone.')),
      );
    }
    return ZepPage(
      title: tx.payeeName.isEmpty ? tx.vpa : tx.payeeName,
      subtitle: tx.status.name.toUpperCase(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MoneyText(
                  tx.amountPaise,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                Text(tx.vpa),
                Text(tx.note.isEmpty ? 'No note' : tx.note),
                Text('Spending · ${tx.category}'),
                Text(
                  '${tx.rail.name} · ${tx.offline ? 'offline' : 'online'} · ${DateFormat('d MMM y, h:mm a').format(tx.createdAt)}',
                ),
                if (tx.refCode.isNotEmpty) Text('Zep Pay ID  ${tx.refCode}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlowButton(
            label: 'SHARE RECEIPT',
            onTap: () => ReceiptShare.share(tx),
          ),
          const SizedBox(height: 10),
          GlowButton(
            label: 'PAY AGAIN',
            onTap: () {
              startPayment(
                ref,
                vpa: tx.vpa,
                amountPaise: tx.amountPaise,
                payeeName: tx.payeeName,
                note: tx.note,
                category: tx.category,
                source: 'again',
              );
              context.push('/pay/amount');
            },
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => ref
                .read(appStoreProvider.notifier)
                .toggleFavorite(tx.vpa, name: tx.payeeName),
            child: const Text('Toggle favourite'),
          ),
        ],
      ),
    );
  }
}

class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({
    super.key,
    required this.groupId,
    required this.expenseId,
  });
  final String groupId;
  final String expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStoreProvider);
    final group = app.groups.where((g) => g.id == groupId).firstOrNull;
    final e = app.expenses.where((x) => x.id == expenseId).firstOrNull;
    if (e == null) {
      return const ZepPage(
        title: 'Bill',
        child: Center(child: Text('Bill missing')),
      );
    }
    String who(String id) =>
        group?.members.where((m) => m.id == id).firstOrNull?.name ?? id;
    return ZepPage(
      title: e.title,
      subtitle:
          '${e.category} · ${e.mode.name} · ${DateFormat('d MMM y').format(e.createdAt)}',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          MoneyText(
            e.amountPaise,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          Text('${e.currency} · FX ${e.fxRate.toStringAsFixed(2)}'),
          if (e.taxPaise > 0) Text('Tax  ₹${(e.taxPaise / 100).toStringAsFixed(2)}'),
          if (e.tipPaise > 0) Text('Tip  ₹${(e.tipPaise / 100).toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          Text('Paid by ${e.payerIds.map(who).join(', ')}'),
          const SizedBox(height: 8),
          ...e.shares.map(
            (s) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(who(s.memberId)),
              trailing: MoneyText(s.amountPaise),
            ),
          ),
          if (e.items.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('ITEMS', style: Theme.of(context).textTheme.labelLarge),
            ...e.items.map(
              (i) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(i.label),
                subtitle: Text(
                  i.assigneeIds.isEmpty
                      ? 'Unassigned'
                      : i.assigneeIds.map(who).join(', '),
                ),
                trailing: MoneyText(i.amountPaise),
              ),
            ),
          ],
          if (e.receiptPath != null && mediaExists(e.receiptPath!)) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image(
                image: mediaImage(e.receiptPath!)!,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CategorySpendScreen extends ConsumerWidget {
  const CategorySpendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(appStoreProvider).expenses;
    final byCat = <String, double>{};
    for (final e in bills) {
      final inr = e.amountPaise / 100 * e.fxRate;
      byCat[e.category] = (byCat[e.category] ?? 0) + inr;
    }
    final entries = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ZepPage(
      title: 'By category',
      subtitle: 'Split bills in INR (FX applied). UPI history is on Spending.',
      child: entries.isEmpty
          ? const Center(child: Text('Log a split bill to see categories.'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        for (var i = 0; i < entries.length; i++)
                          PieChartSectionData(
                            value: entries[i].value,
                            title: entries[i].key,
                            radius: 70,
                            color: Color.lerp(
                              AppColors.hero,
                              AppColors.surfaceHigh,
                              i / (entries.length + 1),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...entries.map(
                  (e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(e.key),
                    trailing: Text('₹${e.value.toStringAsFixed(0)}'),
                  ),
                ),
              ],
            ),
    );
  }
}

Future<void> dialBalanceEnquiry(BuildContext context, WidgetRef ref) async {
  final tel = ref.read(telephonyServiceProvider);
  try {
    await tel.requestPermissions();
    await tel.dial(RailEngine.balanceUssd);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
