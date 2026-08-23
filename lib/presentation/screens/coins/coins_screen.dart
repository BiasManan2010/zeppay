import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/local/app_store.dart';

class CoinsScreen extends ConsumerWidget {
  const CoinsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStoreProvider);
    final fmt = DateFormat('d MMM, h:mm a');

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('ZepCoins'),
        actions: [
          TextButton(
            onPressed: () => context.push('/shop'),
            child: const Text('Shop'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.brandCard,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your balance',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '${app.zepCoinBalance}',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Text(
                  'ZepCoins',
                  style: TextStyle(
                    color: AppColors.heroSoft,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Ways to earn more', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.payments_outlined, color: AppColors.accent),
            title: Text('Pay offline or online'),
            subtitle: Text('1 coin for every ₹10 spent'),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.people_outline, color: AppColors.accent),
            title: Text('Refer a friend'),
            subtitle: Text('Coming soon — demo stub for hackathon'),
          ),
          const SizedBox(height: 16),
          Text('Ledger', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (app.zepCoinLedger.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Complete a payment to earn your first coins.'),
            )
          else
            ...app.zepCoinLedger.map(
              (e) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('+${e.coinsEarned} coins'),
                  subtitle: Text(
                    '₹${(e.amountPaise / 100).toStringAsFixed(0)} payment · ${fmt.format(e.timestamp)}',
                  ),
                  trailing: Text(
                    e.txId.substring(0, 6),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
