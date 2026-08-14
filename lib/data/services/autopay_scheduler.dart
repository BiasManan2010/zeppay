import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_store.dart';
import '../../data/models/models.dart';
import 'notification_service.dart';

final autopaySchedulerProvider = Provider((ref) => AutopayScheduler(ref));

/// Advances due autopay mandates and nudges the user to pay.
class AutopayScheduler {
  AutopayScheduler(this.ref);
  final Ref ref;

  Future<void> tick() async {
    final store = ref.read(appStoreProvider.notifier);
    final now = DateTime.now();
    for (final m in [...ref.read(appStoreProvider).mandates]) {
      if (!m.active || m.nextRun.isAfter(now)) continue;
      if (m.limitPaise > 0 && m.amountPaise > m.limitPaise) continue;
      await NotificationService.instance.ping(
        'Autopay due',
        'Pay ₹${(m.amountPaise / 100).toStringAsFixed(0)} to ${m.payee}',
      );
      await store.addRequest(
        PayRequest(
          id: AppStore.id(),
          fromPhone: 'autopay',
          fromName: 'Autopay · ${m.payee}',
          toPhone: ref.read(appStoreProvider).sessionPhone ?? '',
          toVpa: m.vpa,
          amountPaise: m.amountPaise,
          note: 'Scheduled ${m.frequency.name} payment',
          status: RequestStatus.pending,
          createdAt: DateTime.now(),
        ),
      );
      var next = m.nextRun;
      while (!next.isAfter(now)) {
        next = switch (m.frequency) {
          AutopayFrequency.daily => next.add(const Duration(days: 1)),
          AutopayFrequency.weekly => next.add(const Duration(days: 7)),
          AutopayFrequency.monthly => DateTime(
            next.year,
            next.month + 1,
            next.day,
          ),
        };
      }
      await store.upsertMandate(m.copyWith(nextRun: next));
    }
  }
}
