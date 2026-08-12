import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_store.dart';
import '../../data/models/models.dart';

/// Advances due autopay mandates. Actual payment still goes through the
/// biometric + rail flow when the user taps Run now.
class AutopayScheduler {
  AutopayScheduler(this.ref);
  final Ref ref;

  Future<void> tick() async {
    final store = ref.read(appStoreProvider.notifier);
    final now = DateTime.now();
    for (final m in [...ref.read(appStoreProvider).mandates]) {
      if (!m.active || m.nextRun.isAfter(now)) continue;
      var next = m.nextRun;
      while (!next.isAfter(now)) {
        next = switch (m.frequency) {
          AutopayFrequency.daily => next.add(const Duration(days: 1)),
          AutopayFrequency.weekly => next.add(const Duration(days: 7)),
          AutopayFrequency.monthly => DateTime(next.year, next.month + 1, next.day),
        };
      }
      await store.upsertMandate(m.copyWith(nextRun: next));
    }
  }
}
