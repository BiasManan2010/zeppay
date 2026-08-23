import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/app_store.dart';
import 'phone_hash.dart';
import 'referral_service.dart';

/// Optional referral code entered before OTP verify (signup flow).
final pendingReferralCodeProvider = StateProvider<String>((_) => '');

/// Sync referrer awards for friends who joined with this user's code.
Future<void> syncReferralRewards(WidgetRef ref) async {
  final phone = ref.read(appStoreProvider).sessionPhone;
  if (phone == null || phone.isEmpty) return;
  if (!ReferralService.instance.isReady) return;

  final code = await ReferralService.instance.ensureReferralCode(phone);
  if (code == null) return;

  final hashes = await ReferralService.instance.joinedPhoneHashes(code);
  for (final hash in hashes) {
    await ref.read(appStoreProvider.notifier).awardBonusCoins(
          txId: 'referral-$hash',
          coins: ReferralService.coinsPerJoin,
        );
  }
}

Future<void> completeReferralSignup(WidgetRef ref, String phone) async {
  if (!ReferralService.instance.isReady) return;
  final pending = ref.read(pendingReferralCodeProvider).trim();
  if (pending.isEmpty) return;

  final applied = await ReferralService.instance.applyReferralCode(
    phone: phone,
    code: pending,
  );
  ref.read(pendingReferralCodeProvider.notifier).state = '';

  if (!applied) return;

  final hash = phoneHashForSupabase(phone);
  await ref.read(appStoreProvider.notifier).awardBonusCoins(
        txId: 'referral-signup-$hash',
        coins: ReferralService.coinsPerJoin,
      );
}
