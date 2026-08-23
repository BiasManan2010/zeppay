import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/app_store.dart';
import '../models/user_card.dart';
import 'phone_hash.dart';
import 'supabase_service.dart';

final userCardProvider = FutureProvider.autoDispose<UserCard?>((ref) async {
  final phone = ref.watch(appStoreProvider).sessionPhone;
  if (phone == null || phone.isEmpty) return null;
  if (!SupabaseService.instance.isReady) return null;
  try {
    return await UserCardRepository.instance.cardForPhone(phone);
  } catch (e) {
    debugPrint('userCardProvider: $e');
    return null;
  }
});

final userCardChipIdProvider = FutureProvider.autoDispose<String?>((ref) async {
  final card = await ref.watch(userCardProvider.future);
  if (card == null) return null;
  return UserCardRepository.instance.chipIdForNfc(card.nfcId);
});

class UserCardRepository {
  UserCardRepository._();
  static final instance = UserCardRepository._();

  void _require() => SupabaseService.instance.requireReady();

  Future<String?> resolveUserId(String phone) async {
    _require();
    final hash = phoneHashForSupabase(phone);
    final row = await SupabaseService.instance.client
        .from('app_users')
        .select('id')
        .eq('phone_hash', hash)
        .maybeSingle();
    return row?['id'] as String?;
  }

  Future<UserCard?> cardForUserId(String userId) async {
    _require();
    final row = await SupabaseService.instance.client
        .from('user_cards')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    return UserCard.fromJson(Map<String, dynamic>.from(row));
  }

  Future<UserCard?> cardForPhone(String phone) async {
    final userId = await resolveUserId(phone);
    if (userId == null) return null;
    return cardForUserId(userId);
  }

  Future<String?> chipIdForNfc(String nfcId) async {
    _require();
    final row = await SupabaseService.instance.client
        .from('nfc_tags')
        .select('chip_id')
        .eq('nfc_id', nfcId)
        .maybeSingle();
    return row?['chip_id'] as String?;
  }

  Future<bool> isNfcClaimed(String nfcId) async {
    _require();
    final row = await SupabaseService.instance.client
        .from('user_cards')
        .select('nfc_id')
        .eq('nfc_id', nfcId)
        .maybeSingle();
    return row != null;
  }

  Future<String?> findUnclaimedNfcId() async {
    _require();
    final tags = await SupabaseService.instance.client
        .from('nfc_tags')
        .select('nfc_id')
        .order('nfc_id');
    final claimed = await SupabaseService.instance.client
        .from('user_cards')
        .select('nfc_id');
    final claimedSet = (claimed as List)
        .map((r) => r['nfc_id'] as String)
        .toSet();
    for (final row in tags as List) {
      final id = row['nfc_id'] as String;
      if (!claimedSet.contains(id)) return id;
    }
    return null;
  }

  Future<UserCard> claimCard({
    required String phone,
    required String nfcId,
    required String cardName,
  }) async {
    _require();
    final userId = await resolveUserId(phone);
    if (userId == null) {
      throw StateError(
        'No registered user found. Complete login so your account exists in Supabase.',
      );
    }
    final existing = await cardForUserId(userId);
    if (existing != null) {
      throw StateError('You already have a Zep Card linked.');
    }
    if (await isNfcClaimed(nfcId)) {
      throw StateError('This NFC tag is already linked to another account.');
    }
    final tag = await SupabaseService.instance.client
        .from('nfc_tags')
        .select('nfc_id')
        .eq('nfc_id', nfcId)
        .maybeSingle();
    if (tag == null) {
      throw StateError('Unknown NFC tag id — check the code printed on your card.');
    }
    final row = {
      'user_id': userId,
      'nfc_id': nfcId,
      'card_name': cardName.trim().isEmpty ? 'Cardholder' : cardName.trim(),
      'status': 'active',
    };
    await SupabaseService.instance.client.from('user_cards').insert(row);
    return UserCard(
      userId: userId,
      nfcId: nfcId,
      cardName: row['card_name'] as String,
      claimedAt: DateTime.now(),
    );
  }

  Future<void> updateCardName({
    required String phone,
    required String cardName,
  }) async {
    _require();
    final userId = await resolveUserId(phone);
    if (userId == null) return;
    await SupabaseService.instance.client
        .from('user_cards')
        .update({'card_name': cardName.trim()})
        .eq('user_id', userId);
  }
}
