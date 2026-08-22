import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../services/notification_service.dart';

final appStoreProvider = NotifierProvider<AppStore, AppState>(AppStore.new);

class AppStore extends Notifier<AppState> {
  static const _uuid = Uuid();
  static const _key = 'zeppay_state';

  @override
  AppState build() {
    Future.microtask(hydrate);
    return const AppState();
  }

  Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      final loaded = AppState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      final clean = _withoutDemo(loaded);
      state = clean;
      if (loaded.profile?.balancePaise == 1245000 ||
          loaded.profile?.name.trim().toLowerCase() == 'you' ||
          loaded.groups.any((g) => g.name.toLowerCase() == 'goa trip')) {
        await _persist();
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> login(String phone) async {
    final existing = state.profile;
    final profile = (existing != null && existing.phone == phone)
        ? existing
        : UserProfile(phone: phone);
    state = state.copyWith(sessionPhone: phone, profile: profile);
    await _persist();
  }

  AppState _withoutDemo(AppState s) {
    var profile = s.profile;
    if (profile != null) {
      var next = profile;
      if (next.balancePaise == 1245000) {
        next = next.copyWith(balancePaise: 0);
      }
      if (next.name.trim().toLowerCase() == 'you') {
        next = next.copyWith(name: '');
      }
      profile = next;
    }
    final groups = s.groups.where((g) {
      final demoTrip = g.name.toLowerCase() == 'goa trip' &&
          g.members.any((m) => m.id == 'riya' || m.id == 'arjun');
      return !demoTrip;
    }).toList();
    return s.copyWith(profile: profile, groups: groups);
  }

  Future<void> completeOnboarding({
    required String name,
    required String upiId,
    required String bankName,
    required String accountLast4,
  }) async {
    final p = state.profile;
    if (p == null) return;
    state = state.copyWith(
      profile: p.copyWith(
        name: name,
        upiId: upiId,
        bankName: bankName,
        accountLast4: accountLast4,
        biometricEnrolled: true,
        onboarded: true,
      ),
    );
    await _persist();
  }

  Future<void> logout() async {
    state = state.copyWith(clearSession: true);
    await _persist();
  }

  Future<TxRecord> logTransaction(TxRecord tx) async {
    var next = [tx, ...state.transactions.where((e) => e.id != tx.id)];
    var profile = state.profile;
    if (tx.status == TxStatus.success && profile != null) {
      final already = state.transactions.any(
        (e) => e.id == tx.id && e.status == TxStatus.success,
      );
      if (!already) {
        profile = profile.copyWith(
          balancePaise: profile.balancePaise - tx.amountPaise,
        );
      }
    }
    state = state.copyWith(transactions: next, profile: profile);
    if (tx.status == TxStatus.success) {
      await rememberPayee(
        SavedPayee(
          vpa: tx.vpa,
          name: tx.payeeName.isEmpty ? tx.vpa : tx.payeeName,
        ),
      );
      return tx;
    }
    await _persist();
    return tx;
  }

  Future<void> rememberPayee(SavedPayee payee) async {
    final existing = state.payees.where((p) => p.vpa == payee.vpa).firstOrNull;
    final next = SavedPayee(
      vpa: payee.vpa,
      name: payee.name.isNotEmpty ? payee.name : (existing?.name ?? payee.vpa),
      favorite: existing?.favorite ?? payee.favorite,
    );
    state = state.copyWith(
      payees: [next, ...state.payees.where((p) => p.vpa != payee.vpa)],
    );
    await _persist();
  }

  Future<void> toggleFavorite(String vpa, {String name = ''}) async {
    final existing = state.payees.where((p) => p.vpa == vpa).firstOrNull;
    if (existing == null) {
      await rememberPayee(
        SavedPayee(vpa: vpa, name: name, favorite: true),
      );
      return;
    }
    await rememberPayee(existing.copyWith(favorite: !existing.favorite));
  }

  Future<void> resolveTransaction(String id, TxStatus status) async {
    final existing = state.transactions.where((e) => e.id == id).firstOrNull;
    if (existing == null) return;
    final wasSuccess = existing.status == TxStatus.success;
    await logTransaction(existing.copyWith(status: status));
    if (status == TxStatus.success && !wasSuccess) {
      await awardZepCoins(txId: id, amountPaise: existing.amountPaise);
    }
  }

  Future<void> awardZepCoins({
    required String txId,
    required int amountPaise,
  }) async {
    final coins = amountPaise ~/ 1000;
    if (coins <= 0) return;
    if (state.zepCoinLedger.any((e) => e.txId == txId)) return;
    final entry = ZepCoinLedgerEntry(
      txId: txId,
      amountPaise: amountPaise,
      coinsEarned: coins,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      zepCoinBalance: state.zepCoinBalance + coins,
      zepCoinLedger: [entry, ...state.zepCoinLedger],
    );
    await _persist();
  }

  Future<Redemption?> redeemPartner(PartnerBrand brand) async {
    if (state.zepCoinBalance < brand.coinsRequired) return null;
    final rnd = Random();
    final code =
        'ZEP-${rnd.nextInt(9000) + 1000}-${rnd.nextInt(9000) + 1000}';
    final redemption = Redemption(
      id: _uuid.v4(),
      brandId: brand.id,
      coinsSpent: brand.coinsRequired,
      voucherCode: code,
      redeemedAt: DateTime.now(),
    );
    state = state.copyWith(
      zepCoinBalance: state.zepCoinBalance - brand.coinsRequired,
      redemptions: [redemption, ...state.redemptions],
    );
    await _persist();
    return redemption;
  }

  Future<void> addRequest(PayRequest req) async {
    state = state.copyWith(requests: [req, ...state.requests]);
    await _notify(
      'New payment request',
      '${req.fromName} asked for ₹${(req.amountPaise / 100).toStringAsFixed(0)}',
    );
    await _persist();
  }

  Future<void> updateRequest(String id, RequestStatus status) async {
    state = state.copyWith(
      requests: state.requests
          .map((r) => r.id == id ? r.copyWith(status: status) : r)
          .toList(),
    );
    await _persist();
  }

  Future<void> upsertMandate(AutopayMandate m) async {
    final rest = state.mandates.where((e) => e.id != m.id).toList();
    state = state.copyWith(mandates: [m, ...rest]);
    await _persist();
  }

  Future<void> deleteMandate(String id) async {
    state = state.copyWith(
      mandates: state.mandates.where((e) => e.id != id).toList(),
    );
    await _persist();
  }

  Future<void> upsertGroup(SplitGroup g) async {
    final rest = state.groups.where((e) => e.id != g.id).toList();
    state = state.copyWith(groups: [g, ...rest]);
    await _persist();
  }

  Future<void> deleteGroup(String id) async {
    state = state.copyWith(
      groups: state.groups.where((e) => e.id != id).toList(),
      expenses: state.expenses.where((e) => e.groupId != id).toList(),
      settlements: state.settlements.where((e) => e.groupId != id).toList(),
    );
    await _persist();
  }

  Future<void> updateProfile(UserProfile profile) async {
    state = state.copyWith(profile: profile);
    await _persist();
  }

  Future<void> markNotificationsRead() async {
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.copyWith(read: true))
          .toList(),
    );
    await _persist();
  }

  Future<void> addExpense(Expense e) async {
    state = state.copyWith(expenses: [e, ...state.expenses]);
    await _notify('Split updated', e.title);
    await _persist();
  }

  Future<void> addSettlement(Settlement s) async {
    state = state.copyWith(settlements: [s, ...state.settlements]);
    await _persist();
  }

  Future<void> _notify(String title, String body) async {
    state = state.copyWith(
      notifications: [
        AppNotification(
          id: _uuid.v4(),
          title: title,
          body: body,
          createdAt: DateTime.now(),
        ),
        ...state.notifications,
      ],
    );
    await NotificationService.instance.ping(title, body);
  }

  static String id() => _uuid.v4();

  static String payRef() {
    final t = DateTime.now().microsecondsSinceEpoch
        .toRadixString(36)
        .toUpperCase();
    return 'ZP${t.length > 10 ? t.substring(t.length - 10) : t}';
  }
}
