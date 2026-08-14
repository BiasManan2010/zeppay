import 'dart:convert';

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
      state = AppState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
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
        : UserProfile(phone: phone, name: 'You', balancePaise: 1245000);
    state = state.copyWith(sessionPhone: phone, profile: profile);
    if (state.groups.isEmpty) {
      state = state.copyWith(
        groups: [
          SplitGroup(
            id: id(),
            name: 'Goa trip',
            kind: 'trip',
            members: [
              GroupMember(
                id: 'me',
                name: profile.name.isEmpty ? 'You' : profile.name,
                phone: phone,
                upiId: profile.upiId,
              ),
              const GroupMember(
                id: 'riya',
                name: 'Riya',
                phone: '+919876543210',
                upiId: 'riya@okicici',
              ),
              const GroupMember(
                id: 'arjun',
                name: 'Arjun',
                phone: '+919123456789',
                upiId: 'arjun@ybl',
              ),
            ],
          ),
        ],
      );
    }
    await _persist();
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
    await _persist();
    return tx;
  }

  Future<void> resolveTransaction(String id, TxStatus status) async {
    final existing = state.transactions.where((e) => e.id == id).firstOrNull;
    if (existing == null) return;
    await logTransaction(existing.copyWith(status: status));
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
}
