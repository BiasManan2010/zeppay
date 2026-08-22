import '../models/models.dart';

/// Demo partner brands for hackathon pitch — not real deals.
abstract final class PartnerShop {
  static const demoBadge = 'Demo Partner';

  static const brands = <PartnerBrand>[
    PartnerBrand(
      id: 'zepflix',
      name: 'ZepFlix',
      category: PartnerCategory.ott,
      logoAsset: 'assets/branding/zepflix.png',
      discountLabel: '1 month free',
      coinsRequired: 50,
    ),
    PartnerBrand(
      id: 'bolt-mart',
      name: 'Bolt Mart',
      category: PartnerCategory.shopping,
      logoAsset: 'assets/branding/boltmart.png',
      discountLabel: '₹200 off',
      coinsRequired: 80,
    ),
    PartnerBrand(
      id: 'chai-co',
      name: 'Chai & Co',
      category: PartnerCategory.food,
      logoAsset: 'assets/branding/chaico.png',
      discountLabel: 'Free chai',
      coinsRequired: 30,
    ),
    PartnerBrand(
      id: 'ride-zep',
      name: 'RideZep',
      category: PartnerCategory.travel,
      logoAsset: 'assets/branding/ridezep.png',
      discountLabel: '₹150 ride credit',
      coinsRequired: 100,
    ),
    PartnerBrand(
      id: 'stream-plus',
      name: 'Stream+',
      category: PartnerCategory.ott,
      logoAsset: 'assets/branding/streamplus.png',
      discountLabel: '7-day trial',
      coinsRequired: 40,
    ),
    PartnerBrand(
      id: 'fresh-kart',
      name: 'FreshKart',
      category: PartnerCategory.shopping,
      logoAsset: 'assets/branding/freshkart.png',
      discountLabel: '15% off groceries',
      coinsRequired: 60,
    ),
    PartnerBrand(
      id: 'spice-box',
      name: 'Spice Box',
      category: PartnerCategory.food,
      logoAsset: 'assets/branding/spicebox.png',
      discountLabel: '₹100 off',
      coinsRequired: 45,
    ),
    PartnerBrand(
      id: 'zep-go',
      name: 'ZepGo',
      category: PartnerCategory.travel,
      logoAsset: 'assets/branding/zepgo.png',
      discountLabel: 'Airport lounge pass',
      coinsRequired: 150,
    ),
  ];

  static List<PartnerBrand> byCategory(PartnerCategory cat) =>
      brands.where((b) => b.category == cat).toList();

  static String categoryLabel(PartnerCategory cat) => switch (cat) {
        PartnerCategory.ott => 'OTT',
        PartnerCategory.shopping => 'Shopping',
        PartnerCategory.food => 'Food',
        PartnerCategory.travel => 'Travel',
      };
}
