import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';

final appStoreProvider = NotifierProvider<AppStore, AppState>(AppStore.new);

class AppStore extends Notifier<AppState> {
  static const _uuid = Uuid();
  File? _file;

  @override
  AppState build() {
    Future.microtask(hydrate);
    return const AppState();
  }

  Future<void> hydrate() async {
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/zeppay_state.json');
    if (await _file!.exists()) {
      final raw = jsonDecode(await _file!.readAsString()) as Map<String, dynamic>;
      state = AppState.fromJson(raw);
    }
  }

  Future<void> _persist() async {
    _file ??= File('${(await getApplicationDocumentsDirectory()).path}/zeppay_state.json');
    await _file!.writeAsString(jsonEncode(state.toJson()));
  }

  Future<void> login(String phone) async {
    final existing = state.profile;
    final profile = (existing != null && existing.phone == phone)
        ? existing
        : UserProfile(phone: phone, name: 'You', balancePaise: 1245000);
    state = state.copyWith(sessionPhone: phone, profile: profile);
    if (state.groups.isEmpty) {
      state = state.copyWith(groups: [
        SplitGroup(
          id: id(),
          name: 'Goa trip',
          kind: 'trip',
          members: [
            GroupMember(id: 'me', name: profile.name.isEmpty ? 'You' : profile.name, phone: phone, upiId: profile.upiId),
            const GroupMember(id: 'riya', name: 'Riya', phone: '+919876543210', upiId: 'riya@okicici'),
            const GroupMember(id: 'arjun', name: 'Arjun', phone: '+919123456789', upiId: 'arjun@ybl'),
          ],
        ),
      ]);
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
    var next = [tx, ...state.transactions];
    var profile = state.profile;
    if (tx.status == TxStatus.success && profile != null) {
      profile = profile.copyWith(balancePaise: profile.balancePaise - tx.amountPaise);
    }
    state = state.copyWith(transactions: next, profile: profile);
    await _persist();
    return tx;
  }

  Future<void> addRequest(PayRequest req) async {
    state = state.copyWith(requests: [req, ...state.requests]);
    await _notify('New payment request', '${req.fromName} asked for ₹${(req.amountPaise / 100).toStringAsFixed(0)}');
    await _persist();
  }

  Future<void> updateRequest(String id, RequestStatus status) async {
    state = state.copyWith(
      requests: state.requests.map((r) => r.id == id ? r.copyWith(status: status) : r).toList(),
    );
    await _persist();
  }

  Future<void> upsertMandate(AutopayMandate m) async {
    final rest = state.mandates.where((e) => e.id != m.id).toList();
    state = state.copyWith(mandates: [m, ...rest]);
    await _persist();
  }

  Future<void> upsertGroup(SplitGroup g) async {
    final rest = state.groups.where((e) => e.id != g.id).toList();
    state = state.copyWith(groups: [g, ...rest]);
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
        AppNotification(id: _uuid.v4(), title: title, body: body, createdAt: DateTime.now()),
        ...state.notifications,
      ],
    );
  }

  static String id() => _uuid.v4();
}
