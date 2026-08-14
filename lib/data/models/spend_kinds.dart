import 'package:flutter/material.dart';

class SpendKind {
  const SpendKind({required this.id, required this.label, required this.icon});
  final String id;
  final String label;
  final IconData icon;
}

abstract final class SpendKinds {
  static const food = SpendKind(
    id: 'food',
    label: 'Food',
    icon: Icons.restaurant_rounded,
  );
  static const travel = SpendKind(
    id: 'travel',
    label: 'Travel',
    icon: Icons.directions_car_rounded,
  );
  static const shopping = SpendKind(
    id: 'shopping',
    label: 'Shopping',
    icon: Icons.shopping_bag_rounded,
  );
  static const bills = SpendKind(
    id: 'bills',
    label: 'Bills',
    icon: Icons.receipt_long_rounded,
  );
  static const recharge = SpendKind(
    id: 'recharge',
    label: 'Recharge',
    icon: Icons.phone_android_rounded,
  );
  static const family = SpendKind(
    id: 'family',
    label: 'Family',
    icon: Icons.favorite_rounded,
  );
  static const health = SpendKind(
    id: 'health',
    label: 'Health',
    icon: Icons.local_hospital_rounded,
  );
  static const fun = SpendKind(
    id: 'fun',
    label: 'Fun',
    icon: Icons.movie_rounded,
  );
  static const other = SpendKind(
    id: 'other',
    label: 'Other',
    icon: Icons.category_rounded,
  );

  static const all = [
    food,
    travel,
    shopping,
    bills,
    recharge,
    family,
    health,
    fun,
    other,
  ];

  static SpendKind byId(String id) {
    for (final k in all) {
      if (k.id == id) return k;
    }
    return other;
  }
}
