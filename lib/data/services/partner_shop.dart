import 'package:flutter/material.dart';

import '../models/models.dart';

/// Demo partner brands for hackathon pitch — placeholder names only.
abstract final class PartnerShop {
  static const demoBadge = 'Demo Partner';

  static const brands = <PartnerBrand>[
    // Streaming & Entertainment
    PartnerBrand(
      id: 'zep-stream',
      name: 'ZepStream',
      category: PartnerCategory.streaming,
      accentColor: 0xFFE85D8A,
      discountLabel: '10% off with ZepCoins',
      coinsRequired: 45,
    ),
    PartnerBrand(
      id: 'pulse-tv',
      name: 'PulseTV',
      category: PartnerCategory.streaming,
      accentColor: 0xFF9B6BFF,
      discountLabel: '7-day trial pass',
      coinsRequired: 40,
    ),
    PartnerBrand(
      id: 'wave-music',
      name: 'Wave Music',
      category: PartnerCategory.streaming,
      accentColor: 0xFF5B8DEF,
      discountLabel: '1 month premium',
      coinsRequired: 55,
    ),
    PartnerBrand(
      id: 'arcade-plus',
      name: 'Arcade+',
      category: PartnerCategory.streaming,
      accentColor: 0xFF2D8A5E,
      discountLabel: 'Game credits bundle',
      coinsRequired: 35,
    ),
    // Sportswear & Footwear
    PartnerBrand(
      id: 'stride-lab',
      name: 'Stride Lab',
      category: PartnerCategory.sportswear,
      accentColor: 0xFF1A1A2E,
      discountLabel: '12% off trainers',
      coinsRequired: 90,
    ),
    PartnerBrand(
      id: 'volt-run',
      name: 'Volt Run',
      category: PartnerCategory.sportswear,
      accentColor: 0xFFFF6B35,
      discountLabel: '₹300 off footwear',
      coinsRequired: 85,
    ),
    PartnerBrand(
      id: 'apex-gear',
      name: 'Apex Gear',
      category: PartnerCategory.sportswear,
      accentColor: 0xFF004E89,
      discountLabel: '15% off sportswear',
      coinsRequired: 75,
    ),
    PartnerBrand(
      id: 'kinetic-co',
      name: 'Kinetic Co',
      category: PartnerCategory.sportswear,
      accentColor: 0xFF6C5CE7,
      discountLabel: 'Free socks on ₹999+',
      coinsRequired: 50,
    ),
    // Fitness & Supplements
    PartnerBrand(
      id: 'iron-core',
      name: 'Iron Core',
      category: PartnerCategory.fitness,
      accentColor: 0xFFC0392B,
      discountLabel: '10% off protein',
      coinsRequired: 70,
    ),
    PartnerBrand(
      id: 'flex-gym',
      name: 'Flex Gym',
      category: PartnerCategory.fitness,
      accentColor: 0xFF27AE60,
      discountLabel: '3-day pass',
      coinsRequired: 60,
    ),
    PartnerBrand(
      id: 'zen-yoga',
      name: 'Zen Yoga',
      category: PartnerCategory.fitness,
      accentColor: 0xFF8E44AD,
      discountLabel: 'Online class pack',
      coinsRequired: 45,
    ),
    PartnerBrand(
      id: 'hydra-fit',
      name: 'HydraFit',
      category: PartnerCategory.fitness,
      accentColor: 0xFF3498DB,
      discountLabel: '₹150 off supplements',
      coinsRequired: 55,
    ),
    // Food & Dining
    PartnerBrand(
      id: 'chai-co',
      name: 'Chai & Co',
      category: PartnerCategory.food,
      accentColor: 0xFFD35400,
      discountLabel: 'Free chai with meal',
      coinsRequired: 30,
    ),
    PartnerBrand(
      id: 'spice-box',
      name: 'Spice Box',
      category: PartnerCategory.food,
      accentColor: 0xFFE74C3C,
      discountLabel: '₹100 off delivery',
      coinsRequired: 45,
    ),
    PartnerBrand(
      id: 'urban-bowl',
      name: 'Urban Bowl',
      category: PartnerCategory.food,
      accentColor: 0xFF16A085,
      discountLabel: 'Buy 1 get 1 bowl',
      coinsRequired: 50,
    ),
    PartnerBrand(
      id: 'night-bite',
      name: 'Night Bite',
      category: PartnerCategory.food,
      accentColor: 0xFF2C3E50,
      discountLabel: '20% off after 9pm',
      coinsRequired: 40,
    ),
    // Travel & Ride-hailing
    PartnerBrand(
      id: 'ride-zep',
      name: 'RideZep',
      category: PartnerCategory.travel,
      accentColor: 0xFF2980B9,
      discountLabel: '₹150 ride credit',
      coinsRequired: 100,
    ),
    PartnerBrand(
      id: 'zep-go',
      name: 'ZepGo',
      category: PartnerCategory.travel,
      accentColor: 0xFF1ABC9C,
      discountLabel: 'Airport lounge pass',
      coinsRequired: 150,
    ),
    PartnerBrand(
      id: 'metro-pass',
      name: 'MetroPass',
      category: PartnerCategory.travel,
      accentColor: 0xFF34495E,
      discountLabel: '5% off cab rides',
      coinsRequired: 65,
    ),
    PartnerBrand(
      id: 'stay-nest',
      name: 'StayNest',
      category: PartnerCategory.travel,
      accentColor: 0xFFE67E22,
      discountLabel: '₹500 off stays',
      coinsRequired: 120,
    ),
    // Electronics & Gadgets
    PartnerBrand(
      id: 'circuit-hub',
      name: 'Circuit Hub',
      category: PartnerCategory.electronics,
      accentColor: 0xFF2C3E50,
      discountLabel: '8% off accessories',
      coinsRequired: 95,
    ),
    PartnerBrand(
      id: 'pixel-works',
      name: 'Pixel Works',
      category: PartnerCategory.electronics,
      accentColor: 0xFF8E44AD,
      discountLabel: '₹400 off earbuds',
      coinsRequired: 110,
    ),
    PartnerBrand(
      id: 'volt-tech',
      name: 'Volt Tech',
      category: PartnerCategory.electronics,
      accentColor: 0xFF00B894,
      discountLabel: '10% off chargers',
      coinsRequired: 70,
    ),
    PartnerBrand(
      id: 'gear-grid',
      name: 'Gear Grid',
      category: PartnerCategory.electronics,
      accentColor: 0xFF6C5CE7,
      discountLabel: 'Smart watch discount',
      coinsRequired: 130,
    ),
    // Groceries & Essentials (synergy with Round 2 essential-goods tracking)
    PartnerBrand(
      id: 'fresh-kart',
      name: 'FreshKart',
      category: PartnerCategory.groceries,
      accentColor: 0xFF27AE60,
      discountLabel: '15% off essentials',
      coinsRequired: 60,
    ),
    PartnerBrand(
      id: 'daily-basket',
      name: 'Daily Basket',
      category: PartnerCategory.groceries,
      accentColor: 0xFFF39C12,
      discountLabel: '₹80 off staples',
      coinsRequired: 45,
    ),
    PartnerBrand(
      id: 'home-pantry',
      name: 'Home Pantry',
      category: PartnerCategory.groceries,
      accentColor: 0xFF16A085,
      discountLabel: 'Free delivery on ₹499',
      coinsRequired: 35,
    ),
    PartnerBrand(
      id: 'essentials-plus',
      name: 'Essentials+',
      category: PartnerCategory.groceries,
      accentColor: 0xFF2ECC71,
      discountLabel: 'Track & save on goods you buy',
      coinsRequired: 50,
    ),
  ];

  static List<PartnerBrand> byCategory(PartnerCategory cat) =>
      brands.where((b) => b.category == cat).toList();

  static String categoryLabel(PartnerCategory cat) => switch (cat) {
        PartnerCategory.streaming => 'Streaming & Entertainment',
        PartnerCategory.sportswear => 'Sportswear & Footwear',
        PartnerCategory.fitness => 'Fitness & Supplements',
        PartnerCategory.food => 'Food & Dining',
        PartnerCategory.travel => 'Travel & Ride-hailing',
        PartnerCategory.electronics => 'Electronics & Gadgets',
        PartnerCategory.groceries => 'Groceries & Essentials',
      };

  static String categoryPitch(PartnerCategory cat) => switch (cat) {
        PartnerCategory.groceries =>
          'Pairs with essential-goods tracking — earn coins on staples you already monitor.',
        _ => '',
      };

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].length >= 2
          ? parts[0].substring(0, 2).toUpperCase()
          : parts[0].toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static Color brandColor(PartnerBrand brand) => Color(brand.accentColor);
}
