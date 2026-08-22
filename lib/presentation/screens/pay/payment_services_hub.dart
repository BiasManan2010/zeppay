import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/zep_components.dart';

class PaymentServicesHubScreen extends StatelessWidget {
  const PaymentServicesHubScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        Icons.nfc_rounded,
        'Zep Card',
        () => context.push('/zep-card-setup'),
        const Color(0xFF5B8DEF),
      ),
      (
        Icons.point_of_sale_rounded,
        'Merchant Mode',
        () => context.push('/merchant-mode'),
        const Color(0xFF2D8A5E),
      ),
      (
        Icons.send_rounded,
        'Send to self',
        () => context.push('/pay/upi'),
        const Color(0xFFE87B3A),
      ),
      (
        Icons.event_repeat_rounded,
        'Mandate / Autopay',
        () => context.push('/autopay'),
        const Color(0xFF9B6BFF),
      ),
      (
        Icons.verified_user_outlined,
        'Approve to pay',
        () => context.push('/requests'),
        const Color(0xFF2D8A5E),
      ),
      (
        Icons.card_giftcard_rounded,
        'Gifting',
        () => context.push('/shop'),
        const Color(0xFFE85D8A),
      ),
      (
        Icons.favorite_outline_rounded,
        'Donate',
        () => context.push('/pay/upi'),
        const Color(0xFFC45C4A),
      ),
      (
        Icons.call_received_rounded,
        'Request money',
        () => context.push('/requests'),
        const Color(0xFF5B8DEF),
      ),
      (
        Icons.receipt_long_outlined,
        'My Bills',
        () => context.push('/history'),
        const Color(0xFFE87B3A),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: embedded
          ? null
          : AppBar(
              title: const Text('Payment Services'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => context.pop(),
              ),
            ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, embedded ? 16 : 8, 16, 120),
        children: [
          if (embedded)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Payment Services',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ZepDarkCard(
            padding: const EdgeInsets.all(20),
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.72,
              mainAxisSpacing: 16,
              crossAxisSpacing: 8,
              children: [
                for (final a in actions)
                  ZepQuickAction(
                    icon: a.$1,
                    label: a.$2,
                    tint: a.$4,
                    onTap: a.$3,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ZepPromoBanner(
            headline: 'Earn ZepCoins on every pay',
            subtext: 'Redeem demo partner offers in the Shop',
            chip: '1 coin per ₹10',
            onTap: () => context.push('/coins'),
          ),
        ],
      ),
    );
  }
}
