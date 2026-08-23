import '../../data/models/models.dart';

/// Lightweight ZepCoins gamification derived from existing local data.
abstract final class ZepCoinsGamification {
  static int lifetimeEarned(AppState app) =>
      app.zepCoinLedger.fold<int>(0, (sum, e) => sum + e.coinsEarned);

  static int paymentsThisWeek(AppState app) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return app.transactions
        .where(
          (t) => t.status == TxStatus.success && t.createdAt.isAfter(cutoff),
        )
        .length;
  }

  static String tierLabel(AppState app) {
    final earned = lifetimeEarned(app);
    if (earned >= 500) return 'Gold';
    if (earned >= 150) return 'Silver';
    return 'Bronze';
  }

  static String tierEmoji(AppState app) => switch (tierLabel(app)) {
        'Gold' => '🥇',
        'Silver' => '🥈',
        _ => '🥉',
      };
}
