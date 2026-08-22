import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/models.dart';
import '../../../data/services/partner_shop.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  PartnerCategory _tab = PartnerCategory.ott;

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
            Text(
              '${brand.coinsRequired} ZepCoins required',
              style: const TextStyle(color: Colors.white),
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
            Text(PartnerShop.demoBadge,
                style: const TextStyle(
                    color: AppColors.accent, fontWeight: FontWeight.w600)),
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
    final brands = PartnerShop.byCategory(_tab);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Zep Shop')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: PartnerCategory.values.map((c) {
                final selected = _tab == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(PartnerShop.categoryLabel(c)),
                    selected: selected,
                    onSelected: (_) => setState(() => _tab = c),
                    selectedColor: AppColors.accent.withValues(alpha: 0.25),
                    checkmarkColor: AppColors.accent,
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: brands.length,
              itemBuilder: (context, i) {
                final b = brands[i];
                return Card(
                  child: InkWell(
                    onTap: () => _redeem(b),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _iconFor(b.category),
                              color: AppColors.accent,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            PartnerShop.demoBadge,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.accent,
                                  fontSize: 9,
                                ),
                          ),
                          Text(
                            b.name,
                            style: Theme.of(context).textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            b.discountLabel,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${b.coinsRequired} coins',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.forest,
                            ),
                          ),
                        ],
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

  IconData _iconFor(PartnerCategory c) => switch (c) {
        PartnerCategory.ott => Icons.movie_outlined,
        PartnerCategory.shopping => Icons.shopping_bag_outlined,
        PartnerCategory.food => Icons.restaurant_outlined,
        PartnerCategory.travel => Icons.flight_outlined,
      };
}
