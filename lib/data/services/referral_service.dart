import 'package:flutter/foundation.dart';

import 'phone_hash.dart';
import 'supabase_service.dart';

/// Referral identity in Supabase + local ZepCoins awards.
///
/// Zero-cost acquisition: share existing referral codes, award via the same
/// local ZepCoins ledger used for payment rewards — no ad spend, no new coins DB.
class ReferralService {
  ReferralService._();
  static final instance = ReferralService._();

  /// Coins granted to inviter and invitee per successful referral join.
  static const coinsPerJoin = 25;

  bool get isReady => SupabaseService.instance.isReady;

  Future<String?> ensureReferralCode(String phone) async {
    if (!isReady) return null;
    try {
      final hash = phoneHashForSupabase(phone);
      final result = await SupabaseService.instance.client.rpc(
        'ensure_referral_code',
        params: {'p_hash': hash},
      );
      return result as String?;
    } catch (e) {
      debugPrint('ensureReferralCode: $e');
      return null;
    }
  }

  Future<bool> applyReferralCode({
    required String phone,
    required String code,
  }) async {
    if (!isReady || code.trim().isEmpty) return false;
    try {
      final hash = phoneHashForSupabase(phone);
      final ok = await SupabaseService.instance.client.rpc(
        'apply_referral_code',
        params: {'p_hash': hash, 'p_code': code.trim()},
      );
      return ok == true;
    } catch (e) {
      debugPrint('applyReferralCode: $e');
      return false;
    }
  }

  Future<int> friendCount(String referralCode) async {
    if (!isReady) return 0;
    try {
      final count = await SupabaseService.instance.client.rpc(
        'referral_friend_count',
        params: {'p_code': referralCode},
      );
      return (count as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('friendCount: $e');
      return 0;
    }
  }

  Future<List<String>> joinedPhoneHashes(String referralCode) async {
    if (!isReady) return const [];
    try {
      final rows = await SupabaseService.instance.client.rpc(
        'referral_joined_hashes',
        params: {'p_code': referralCode},
      );
      if (rows is List) {
        return rows.map((e) => '$e').toList();
      }
      return const [];
    } catch (e) {
      debugPrint('joinedPhoneHashes: $e');
      return const [];
    }
  }

  Future<bool> isValidReferralCode(String code) async {
    if (!isReady || code.trim().isEmpty) return false;
    try {
      final row = await SupabaseService.instance.client
          .from('app_users')
          .select('referral_code')
          .eq('referral_code', code.trim().toUpperCase())
          .maybeSingle();
      return row != null;
    } catch (e) {
      debugPrint('isValidReferralCode: $e');
      return false;
    }
  }
}
