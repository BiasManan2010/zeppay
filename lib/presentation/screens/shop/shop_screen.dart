import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/zep_coin_icon.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/models.dart';
import '../../../data/services/partner_shop.dart';
import '../../../data/services/zep_coins_gamification.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  Future<void> _redeem(PartnerBrand brand) async {
    final balance = ref.read(appStoreProvider).zepCoinBalance;
    if (balance < brand.coinsRequired) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Need ${brand.coinsRequired} coins — you have $balance',
          ),
        ),
      );
      return;
    }
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              brand.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              PartnerShop.demoBadge,
              style: TextStyle(color: AppColors.accent.withValues(alpha: 0.9)),
            ),
            const SizedBox(height: 12),
            Text(
              brand.discountLabel,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const ZepCoinIcon(size: 20),
                const SizedBox(width: 6),
                Text(
                  '${brand.coinsRequired} ZepCoins required',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                ),
                child: const Text('Redeem'),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    final redemption =
        await ref.read(appStoreProvider.notifier).redeemPartner(brand);
    if (!mounted || redemption == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${brand.name} voucher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              PartnerShop.demoBadge,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              redemption.voucherCode,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Demo voucher — not a real partner deal.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appStoreProvider);
    final tier = ZepCoinsGamification.tierLabel(app);
    final streak = ZepCoinsGamification.paymentsThisWeek(app);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Zep Shop'),
        actions: [
          TextButton(
            onPressed: () => context.push('/coins'),
            child: const Text('Coins'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _GamificationHeader(
            balance: app.zepCoinBalance,
            tier: tier,
            paymentsThisWeek: streak,
          ),
          const SizedBox(height: 16),
          for (final cat in PartnerCategory.values) ...[
            _CategorySection(
              category: cat,
              brands: PartnerShop.byCategory(cat),
              onRedeem: _redeem,
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _GamificationHeader extends StatelessWidget {
  const _GamificationHeader({
    required this.balance,
    required this.tier,
    required this.paymentsThisWeek,
  });

  final int balance;
  final String tier;
  final int paymentsThisWeek;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.forestCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const ZepCoinIcon(size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$balance ZepCoins',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  '$tier tier · $paymentsThisWeek payments this week',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.brands,
    required this.onRedeem,
  });

  final PartnerCategory category;
  final List<PartnerBrand> brands;
  final void Function(PartnerBrand) onRedeem;

  @override
  Widget build(BuildContext context) {
    final pitch = PartnerShop.categoryPitch(category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          PartnerShop.categoryLabel(category),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        if (pitch.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            pitch,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.forest,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
        const SizedBox(height: 10),
        ...brands.map(
          (b) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PartnerCard(brand: b, onTap: () => onRedeem(b)),
          ),
        ),
      ],
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({required this.brand, required this.onTap});

  final PartnerBrand brand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = PartnerShop.brandColor(brand);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.45)),
                ),
                child: Text(
                  PartnerShop.initials(brand.name),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      PartnerShop.demoBadge,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.accent,
                            fontSize: 9,
                          ),
                    ),
                    Text(
                      brand.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      brand.discountLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const ZepCoinIcon(size: 18),
                  const SizedBox(height: 4),
                  Text(
                    '${brand.coinsRequired}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.forest,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
