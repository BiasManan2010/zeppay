import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../local/app_store.dart';
import 'biometric_service.dart';
import 'contacts_access.dart';
import 'otp_service.dart';
import 'telephony_service.dart';
import 'security_audit.dart';
import 'payment_session.dart';

final otpServiceProvider = Provider((_) => OtpService());
final biometricServiceProvider = Provider((_) => BiometricService());
final telephonyServiceProvider = Provider((_) => TelephonyService());

final paymentDraftProvider = StateProvider<PaymentDraft?>((_) => null);
final pendingPhoneProvider = StateProvider<String>((_) => '');
final lastRailProvider = StateProvider<PaymentRail?>((_) => null);
final pendingTxIdProvider = StateProvider<String?>((_) => null);

class SplitPrefill {
  const SplitPrefill({
    required this.amountPaise,
    required this.payeeName,
    required this.category,
    this.title,
  });

  final int amountPaise;
  final String payeeName;
  final String category;
  final String? title;
}

final splitPrefillProvider = StateProvider<SplitPrefill?>((_) => null);
final lastCoinsEarnedProvider = StateProvider<int>((_) => 0);

final otpLiveProvider = FutureProvider((ref) {
  return ref.watch(otpServiceProvider).isLive();
});

final phoneContactsProvider = FutureProvider((ref) {
  return ContactsAccess.load(requestIfNeeded: false);
});

void startPayment(
  WidgetRef ref, {
  required String vpa,
  required int amountPaise,
  String payeeName = '',
  String note = '',
  String source = 'pay',
  String category = 'other',
  String? requestId,
  String? settleGroupId,
  String? settleFromId,
  String? settleToId,
}) {
  ref.read(paymentDraftProvider.notifier).state = PaymentDraft(
    vpa: vpa,
    amountPaise: amountPaise,
    payeeName: payeeName,
    note: note,
    source: source,
    category: category,
    requestId: requestId,
    settleGroupId: settleGroupId,
    settleFromId: settleFromId,
    settleToId: settleToId,
  );
}

final networkInfoProvider = FutureProvider((ref) {
  return ref.watch(telephonyServiceProvider).networkInfo();
});

Future<void> hapticTap() async {
  await HapticFeedback.lightImpact();
}

Future<void> hapticLock() async {
  await HapticFeedback.mediumImpact();
}

Future<void> applyPaymentResult(WidgetRef ref, TxStatus status) async {
  final id = ref.read(pendingTxIdProvider);
  if (id != null) {
    final existing = ref
        .read(appStoreProvider)
        .transactions
        .where((t) => t.id == id)
        .firstOrNull;
    await ref.read(appStoreProvider.notifier).resolveTransaction(id, status);
    final audit = await ref.read(securityAuditProvider.future);
    await audit.paymentResolved(id, status);
    if (status == TxStatus.success && existing != null) {
      ref.read(lastCoinsEarnedProvider.notifier).state =
          existing.amountPaise ~/ 1000;
    }
  }
  await ref.read(paymentSessionProvider.notifier).resolve(status);
  final draft = ref.read(paymentDraftProvider);
  if (status == TxStatus.success && draft?.requestId != null) {
    await ref
        .read(appStoreProvider.notifier)
        .updateRequest(draft!.requestId!, RequestStatus.paid);
  }
  if (status == TxStatus.success &&
      draft?.settleGroupId != null &&
      draft?.settleFromId != null &&
      draft?.settleToId != null) {
    await ref.read(appStoreProvider.notifier).addSettlement(
          Settlement(
            id: AppStore.id(),
            groupId: draft!.settleGroupId!,
            fromId: draft.settleFromId!,
            toId: draft.settleToId!,
            amountPaise: draft.amountPaise,
            createdAt: DateTime.now(),
            method: 'in_app',
          ),
        );
  }
}

String routeForTxStatus(TxStatus status) {
  switch (status) {
    case TxStatus.success:
      return '/confirm';
    case TxStatus.pending:
      return '/pending';
    case TxStatus.failed:
      return '/failed';
  }
}

/// Restore draft + pending tx when a tracked payment still needs confirmation.
void resumePendingPaymentTrack(WidgetRef ref) {
  final track = ref.read(paymentSessionProvider).value?.track;
  if (track == null || !track.needsConfirmation) return;
  ref.read(pendingTxIdProvider.notifier).state = track.txId;
  final app = ref.read(appStoreProvider);
  final tx = app.transactions.where((t) => t.id == track.txId).firstOrNull;
  if (tx == null) return;
  ref.read(paymentDraftProvider.notifier).state = PaymentDraft(
    vpa: tx.vpa,
    amountPaise: tx.amountPaise,
    payeeName: tx.payeeName,
    note: tx.note,
    category: tx.category,
    source: 'track',
  );
}
