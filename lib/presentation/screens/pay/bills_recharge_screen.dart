import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/chrome.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/spend_kinds.dart';
import '../../../data/services/providers.dart';

/// Demo bill category — hardcoded local list, not fetched.
class BillCategory {
  const BillCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.spendId,
  });

  final String id;
  final String title;
  final IconData icon;
  final String spendId;
}

/// Demo-only bill pay / recharge — no real biller integration.
class BillsRechargeHubScreen extends StatelessWidget {
  const BillsRechargeHubScreen({super.key});

  static const categories = [
    BillCategory(
      id: 'recharge',
      title: 'Mobile Recharge',
      icon: Icons.phone_android_rounded,
      spendId: 'recharge',
    ),
    BillCategory(
      id: 'electricity',
      title: 'Electricity',
      icon: Icons.bolt_rounded,
      spendId: 'bills',
    ),
    BillCategory(
      id: 'dth',
      title: 'DTH',
      icon: Icons.live_tv_rounded,
      spendId: 'bills',
    ),
    BillCategory(
      id: 'water',
      title: 'Water',
      icon: Icons.water_drop_rounded,
      spendId: 'bills',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ZepPage(
      title: 'Bills & Recharge',
      subtitle: 'Demo flow — records like a normal payment, no real biller',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          for (final c in categories)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SurfaceCard(
                onTap: () => context.push('/bills-recharge/${c.id}'),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(c.icon, color: AppColors.accent),
                  title: Text(c.title),
                  subtitle: Text(SpendKinds.byId(c.spendId).label),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BillRechargeFormScreen extends ConsumerStatefulWidget {
  const BillRechargeFormScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  ConsumerState<BillRechargeFormScreen> createState() =>
      _BillRechargeFormScreenState();
}

class _BillRechargeFormScreenState extends ConsumerState<BillRechargeFormScreen> {
  final _provider = TextEditingController();
  final _account = TextEditingController();
  final _amount = TextEditingController();

  @override
  void dispose() {
    _provider.dispose();
    _account.dispose();
    _amount.dispose();
    super.dispose();
  }

  BillCategory? get _cat =>
      BillsRechargeHubScreen.categories
          .where((c) => c.id == widget.categoryId)
          .firstOrNull;

  void _submit() {
    final cat = _cat;
    if (cat == null) return;
    final rupees = double.tryParse(_amount.text.trim()) ?? 0;
    if (rupees <= 0 || _provider.text.trim().isEmpty) return;
    // Demo merchant VPA — not a real biller; payment still uses honest rails.
    startPayment(
      ref,
      vpa: 'demo.bills@zeppay',
      amountPaise: (rupees * 100).round(),
      payeeName: '${cat.title} · ${_provider.text.trim()}',
      note: 'Demo acct ${_account.text.trim()}',
      source: 'bills_demo',
      category: cat.spendId,
    );
    context.push('/pay/amount');
  }

  @override
  Widget build(BuildContext context) {
    final cat = _cat;
    if (cat == null) {
      return const ZepPage(
        title: 'Bills',
        child: Center(child: Text('Unknown category')),
      );
    }
    return ZepPage(
      title: cat.title,
      subtitle: 'Demo only — confirm in *99# like any other pay',
      footer: GlowButton(label: 'CONTINUE TO PAY', onTap: _submit),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          TextField(
            controller: _provider,
            decoration: InputDecoration(
              labelText: cat.id == 'recharge' ? 'OPERATOR' : 'PROVIDER',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _account,
            decoration: InputDecoration(
              labelText:
                  cat.id == 'recharge' ? 'MOBILE NUMBER' : 'ACCOUNT / CONSUMER ID',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            decoration: const InputDecoration(labelText: 'AMOUNT (₹)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
    );
  }
}

class SelfTransferScreen extends ConsumerWidget {
  const SelfTransferScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(appStoreProvider).profile;
    final vpa = profile?.upiId ?? '';
    return ZepPage(
      title: 'Send to self',
      subtitle: 'Move money between your own accounts via UPI',
      footer: vpa.contains('@')
          ? GlowButton(
              label: 'CONTINUE',
              onTap: () {
                startPayment(
                  ref,
                  vpa: vpa,
                  amountPaise: 0,
                  payeeName: profile?.name ?? 'Self',
                  source: 'self',
                );
                context.push('/pay/amount');
              },
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          vpa.contains('@')
              ? 'Pay to your UPI ID: $vpa'
              : 'Add your UPI ID in Profile first.',
        ),
      ),
    );
  }
}

class DonateScreen extends ConsumerWidget {
  const DonateScreen({super.key});

  static const _causes = [
    ('Relief fund', 'relief@zeppay'),
    ('Education', 'edu@zeppay'),
    ('Animal care', 'paws@zeppay'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ZepPage(
      title: 'Donate',
      subtitle: 'Demo charities — same honest payment flow',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          for (final c in _causes)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SurfaceCard(
                onTap: () {
                  startPayment(
                    ref,
                    vpa: c.$2,
                    amountPaise: 0,
                    payeeName: c.$1,
                    source: 'donate',
                    category: 'family',
                  );
                  context.push('/pay/amount');
                },
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.favorite_rounded,
                      color: AppColors.accent),
                  title: Text(c.$1),
                  subtitle: Text(c.$2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
