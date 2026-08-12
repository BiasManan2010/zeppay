import '../models/models.dart';

class SplitMath {
  static List<ExpenseShare> compute({
    required SplitMode mode,
    required int totalPaise,
    required List<GroupMember> members,
    Map<String, int>? exact,
    Map<String, double>? percents,
    Map<String, double>? shares,
    List<LineItem>? items,
  }) {
    if (members.isEmpty) return const [];
    switch (mode) {
      case SplitMode.equal:
        final each = totalPaise ~/ members.length;
        final rem = totalPaise - each * members.length;
        return [
          for (var i = 0; i < members.length; i++)
            ExpenseShare(
              memberId: members[i].id,
              amountPaise: each + (i == 0 ? rem : 0),
            ),
        ];
      case SplitMode.exact:
        return members
            .map((m) => ExpenseShare(memberId: m.id, amountPaise: exact?[m.id] ?? 0))
            .toList();
      case SplitMode.percent:
        return members.map((m) {
          final p = percents?[m.id] ?? 0;
          return ExpenseShare(memberId: m.id, amountPaise: (totalPaise * p / 100).round());
        }).toList();
      case SplitMode.shares:
        final denom = members.fold<double>(0, (s, m) => s + (shares?[m.id] ?? m.defaultShare));
        return members.map((m) {
          final sh = shares?[m.id] ?? m.defaultShare;
          return ExpenseShare(
            memberId: m.id,
            amountPaise: denom == 0 ? 0 : (totalPaise * sh / denom).round(),
          );
        }).toList();
      case SplitMode.itemized:
        final map = <String, int>{};
        for (final item in items ?? const <LineItem>[]) {
          if (item.assigneeIds.isEmpty) continue;
          final each = item.amountPaise ~/ item.assigneeIds.length;
          for (final id in item.assigneeIds) {
            map[id] = (map[id] ?? 0) + each;
          }
        }
        return members
            .map((m) => ExpenseShare(memberId: m.id, amountPaise: map[m.id] ?? 0))
            .toList();
    }
  }

  /// Minimize number of settling payments (greedy).
  static List<({String from, String to, int amount})> simplify({
    required List<GroupMember> members,
    required List<Expense> expenses,
    required List<Settlement> settlements,
  }) {
    final net = {for (final m in members) m.id: 0};
    for (final e in expenses) {
      final payShare = e.payerIds.isEmpty ? 0 : e.amountPaise ~/ e.payerIds.length;
      for (final pid in e.payerIds) {
        net[pid] = (net[pid] ?? 0) + payShare;
      }
      for (final s in e.shares) {
        net[s.memberId] = (net[s.memberId] ?? 0) - s.amountPaise;
      }
    }
    for (final s in settlements) {
      net[s.fromId] = (net[s.fromId] ?? 0) + s.amountPaise;
      net[s.toId] = (net[s.toId] ?? 0) - s.amountPaise;
    }

    final debtors = <MapEntry<String, int>>[];
    final creditors = <MapEntry<String, int>>[];
    net.forEach((id, v) {
      if (v < -1) debtors.add(MapEntry(id, -v));
      if (v > 1) creditors.add(MapEntry(id, v));
    });
    debtors.sort((a, b) => b.value.compareTo(a.value));
    creditors.sort((a, b) => b.value.compareTo(a.value));

    final out = <({String from, String to, int amount})>[];
    var i = 0;
    var j = 0;
    while (i < debtors.length && j < creditors.length) {
      final pay = debtors[i].value < creditors[j].value ? debtors[i].value : creditors[j].value;
      out.add((from: debtors[i].key, to: creditors[j].key, amount: pay));
      debtors[i] = MapEntry(debtors[i].key, debtors[i].value - pay);
      creditors[j] = MapEntry(creditors[j].key, creditors[j].value - pay);
      if (debtors[i].value <= 1) i++;
      if (creditors[j].value <= 1) j++;
    }
    return out;
  }
}
