enum TxStatus { success, pending, failed }

enum PaymentRail { ussd, ivr, upiIntent }

enum SplitMode { equal, exact, percent, shares, itemized }

enum RequestStatus { pending, accepted, declined, paid }

enum AutopayFrequency { daily, weekly, monthly }

class UserProfile {
  const UserProfile({
    required this.phone,
    this.name = '',
    this.upiId = '',
    this.bankName = '',
    this.accountLast4 = '',
    this.balancePaise = 0,
    this.biometricEnrolled = false,
    this.onboarded = false,
  });

  final String phone;
  final String name;
  final String upiId;
  final String bankName;
  final String accountLast4;
  final int balancePaise;
  final bool biometricEnrolled;
  final bool onboarded;

  UserProfile copyWith({
    String? phone,
    String? name,
    String? upiId,
    String? bankName,
    String? accountLast4,
    int? balancePaise,
    bool? biometricEnrolled,
    bool? onboarded,
  }) {
    return UserProfile(
      phone: phone ?? this.phone,
      name: name ?? this.name,
      upiId: upiId ?? this.upiId,
      bankName: bankName ?? this.bankName,
      accountLast4: accountLast4 ?? this.accountLast4,
      balancePaise: balancePaise ?? this.balancePaise,
      biometricEnrolled: biometricEnrolled ?? this.biometricEnrolled,
      onboarded: onboarded ?? this.onboarded,
    );
  }

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'name': name,
    'upiId': upiId,
    'bankName': bankName,
    'accountLast4': accountLast4,
    'balancePaise': balancePaise,
    'biometricEnrolled': biometricEnrolled,
    'onboarded': onboarded,
  };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    phone: j['phone'] as String? ?? '',
    name: j['name'] as String? ?? '',
    upiId: j['upiId'] as String? ?? '',
    bankName: j['bankName'] as String? ?? '',
    accountLast4: j['accountLast4'] as String? ?? '',
    balancePaise: j['balancePaise'] as int? ?? 0,
    biometricEnrolled: j['biometricEnrolled'] as bool? ?? false,
    onboarded: j['onboarded'] as bool? ?? false,
  );
}

class PaymentDraft {
  const PaymentDraft({
    required this.vpa,
    required this.amountPaise,
    this.payeeName = '',
    this.note = '',
    this.source = 'scan',
    this.currency = 'INR',
  });

  final String vpa;
  final int amountPaise;
  final String payeeName;
  final String note;
  final String source;
  final String currency;

  double get amountRupees => amountPaise / 100.0;
}

class TxRecord {
  const TxRecord({
    required this.id,
    required this.vpa,
    required this.amountPaise,
    required this.status,
    required this.createdAt,
    this.payeeName = '',
    this.note = '',
    this.rail = PaymentRail.ussd,
    this.offline = true,
    this.currency = 'INR',
  });

  final String id;
  final String vpa;
  final String payeeName;
  final int amountPaise;
  final TxStatus status;
  final DateTime createdAt;
  final String note;
  final PaymentRail rail;
  final bool offline;
  final String currency;

  TxRecord copyWith({TxStatus? status}) => TxRecord(
    id: id,
    vpa: vpa,
    payeeName: payeeName,
    amountPaise: amountPaise,
    status: status ?? this.status,
    createdAt: createdAt,
    note: note,
    rail: rail,
    offline: offline,
    currency: currency,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'vpa': vpa,
    'payeeName': payeeName,
    'amountPaise': amountPaise,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'note': note,
    'rail': rail.name,
    'offline': offline,
    'currency': currency,
  };

  factory TxRecord.fromJson(Map<String, dynamic> j) => TxRecord(
    id: j['id'] as String,
    vpa: j['vpa'] as String? ?? '',
    payeeName: j['payeeName'] as String? ?? '',
    amountPaise: j['amountPaise'] as int? ?? 0,
    status: TxStatus.values.byName(j['status'] as String? ?? 'pending'),
    createdAt: DateTime.parse(j['createdAt'] as String),
    note: j['note'] as String? ?? '',
    rail: PaymentRail.values.byName(j['rail'] as String? ?? 'ussd'),
    offline: j['offline'] as bool? ?? true,
    currency: j['currency'] as String? ?? 'INR',
  );
}

class PayRequest {
  const PayRequest({
    required this.id,
    required this.fromPhone,
    required this.toPhone,
    required this.amountPaise,
    required this.status,
    required this.createdAt,
    this.note = '',
    this.fromName = '',
    this.toVpa = '',
  });

  final String id;
  final String fromPhone;
  final String fromName;
  final String toPhone;
  final String toVpa;
  final int amountPaise;
  final String note;
  final RequestStatus status;
  final DateTime createdAt;

  PayRequest copyWith({RequestStatus? status}) => PayRequest(
    id: id,
    fromPhone: fromPhone,
    fromName: fromName,
    toPhone: toPhone,
    toVpa: toVpa,
    amountPaise: amountPaise,
    note: note,
    status: status ?? this.status,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromPhone': fromPhone,
    'fromName': fromName,
    'toPhone': toPhone,
    'toVpa': toVpa,
    'amountPaise': amountPaise,
    'note': note,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PayRequest.fromJson(Map<String, dynamic> j) => PayRequest(
    id: j['id'] as String,
    fromPhone: j['fromPhone'] as String? ?? '',
    fromName: j['fromName'] as String? ?? '',
    toPhone: j['toPhone'] as String? ?? '',
    toVpa: j['toVpa'] as String? ?? '',
    amountPaise: j['amountPaise'] as int? ?? 0,
    note: j['note'] as String? ?? '',
    status: RequestStatus.values.byName(j['status'] as String? ?? 'pending'),
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}

class AutopayMandate {
  const AutopayMandate({
    required this.id,
    required this.payee,
    required this.vpa,
    required this.amountPaise,
    required this.frequency,
    required this.nextRun,
    this.limitPaise = 0,
    this.active = true,
    this.note = '',
  });

  final String id;
  final String payee;
  final String vpa;
  final int amountPaise;
  final AutopayFrequency frequency;
  final DateTime nextRun;
  final int limitPaise;
  final bool active;
  final String note;

  AutopayMandate copyWith({
    bool? active,
    DateTime? nextRun,
    int? amountPaise,
    int? limitPaise,
    AutopayFrequency? frequency,
  }) => AutopayMandate(
    id: id,
    payee: payee,
    vpa: vpa,
    amountPaise: amountPaise ?? this.amountPaise,
    frequency: frequency ?? this.frequency,
    nextRun: nextRun ?? this.nextRun,
    limitPaise: limitPaise ?? this.limitPaise,
    active: active ?? this.active,
    note: note,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'payee': payee,
    'vpa': vpa,
    'amountPaise': amountPaise,
    'frequency': frequency.name,
    'nextRun': nextRun.toIso8601String(),
    'limitPaise': limitPaise,
    'active': active,
    'note': note,
  };

  factory AutopayMandate.fromJson(Map<String, dynamic> j) => AutopayMandate(
    id: j['id'] as String,
    payee: j['payee'] as String? ?? '',
    vpa: j['vpa'] as String? ?? '',
    amountPaise: j['amountPaise'] as int? ?? 0,
    frequency: AutopayFrequency.values.byName(
      j['frequency'] as String? ?? 'monthly',
    ),
    nextRun: DateTime.parse(j['nextRun'] as String),
    limitPaise: j['limitPaise'] as int? ?? 0,
    active: j['active'] as bool? ?? true,
    note: j['note'] as String? ?? '',
  );
}

class GroupMember {
  const GroupMember({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.upiId = '',
    this.defaultShare = 1,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String upiId;
  final double defaultShare;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'upiId': upiId,
    'defaultShare': defaultShare,
  };

  factory GroupMember.fromJson(Map<String, dynamic> j) => GroupMember(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    email: j['email'] as String? ?? '',
    upiId: j['upiId'] as String? ?? '',
    defaultShare: (j['defaultShare'] as num?)?.toDouble() ?? 1,
  );
}

class LineItem {
  const LineItem({
    required this.label,
    required this.amountPaise,
    this.assigneeIds = const [],
  });

  final String label;
  final int amountPaise;
  final List<String> assigneeIds;

  Map<String, dynamic> toJson() => {
    'label': label,
    'amountPaise': amountPaise,
    'assigneeIds': assigneeIds,
  };

  factory LineItem.fromJson(Map<String, dynamic> j) => LineItem(
    label: j['label'] as String? ?? '',
    amountPaise: j['amountPaise'] as int? ?? 0,
    assigneeIds: (j['assigneeIds'] as List?)?.cast<String>() ?? const [],
  );
}

class ExpenseShare {
  const ExpenseShare({required this.memberId, required this.amountPaise});
  final String memberId;
  final int amountPaise;

  Map<String, dynamic> toJson() => {
    'memberId': memberId,
    'amountPaise': amountPaise,
  };
  factory ExpenseShare.fromJson(Map<String, dynamic> j) => ExpenseShare(
    memberId: j['memberId'] as String,
    amountPaise: j['amountPaise'] as int? ?? 0,
  );
}

class Expense {
  const Expense({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amountPaise,
    required this.createdAt,
    required this.payerIds,
    required this.shares,
    this.mode = SplitMode.equal,
    this.currency = 'INR',
    this.fxRate = 1,
    this.category = 'general',
    this.note = '',
    this.receiptPath,
    this.items = const [],
    this.taxPaise = 0,
    this.tipPaise = 0,
  });

  final String id;
  final String groupId;
  final String title;
  final int amountPaise;
  final DateTime createdAt;
  final List<String> payerIds;
  final List<ExpenseShare> shares;
  final SplitMode mode;
  final String currency;
  final double fxRate;
  final String category;
  final String note;
  final String? receiptPath;
  final List<LineItem> items;
  final int taxPaise;
  final int tipPaise;

  Map<String, dynamic> toJson() => {
    'id': id,
    'groupId': groupId,
    'title': title,
    'amountPaise': amountPaise,
    'createdAt': createdAt.toIso8601String(),
    'payerIds': payerIds,
    'shares': shares.map((e) => e.toJson()).toList(),
    'mode': mode.name,
    'currency': currency,
    'fxRate': fxRate,
    'category': category,
    'note': note,
    'receiptPath': receiptPath,
    'items': items.map((e) => e.toJson()).toList(),
    'taxPaise': taxPaise,
    'tipPaise': tipPaise,
  };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
    id: j['id'] as String,
    groupId: j['groupId'] as String,
    title: j['title'] as String? ?? '',
    amountPaise: j['amountPaise'] as int? ?? 0,
    createdAt: DateTime.parse(j['createdAt'] as String),
    payerIds: (j['payerIds'] as List?)?.cast<String>() ?? const [],
    shares: (j['shares'] as List? ?? [])
        .map((e) => ExpenseShare.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    mode: SplitMode.values.byName(j['mode'] as String? ?? 'equal'),
    currency: j['currency'] as String? ?? 'INR',
    fxRate: (j['fxRate'] as num?)?.toDouble() ?? 1,
    category: j['category'] as String? ?? 'general',
    note: j['note'] as String? ?? '',
    receiptPath: j['receiptPath'] as String?,
    items: (j['items'] as List? ?? [])
        .map((e) => LineItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    taxPaise: j['taxPaise'] as int? ?? 0,
    tipPaise: j['tipPaise'] as int? ?? 0,
  );
}

class Settlement {
  const Settlement({
    required this.id,
    required this.groupId,
    required this.fromId,
    required this.toId,
    required this.amountPaise,
    required this.createdAt,
    this.method = 'in_app',
    this.note = '',
  });

  final String id;
  final String groupId;
  final String fromId;
  final String toId;
  final int amountPaise;
  final DateTime createdAt;
  final String method;
  final String note;

  Map<String, dynamic> toJson() => {
    'id': id,
    'groupId': groupId,
    'fromId': fromId,
    'toId': toId,
    'amountPaise': amountPaise,
    'createdAt': createdAt.toIso8601String(),
    'method': method,
    'note': note,
  };

  factory Settlement.fromJson(Map<String, dynamic> j) => Settlement(
    id: j['id'] as String,
    groupId: j['groupId'] as String,
    fromId: j['fromId'] as String,
    toId: j['toId'] as String,
    amountPaise: j['amountPaise'] as int? ?? 0,
    createdAt: DateTime.parse(j['createdAt'] as String),
    method: j['method'] as String? ?? 'in_app',
    note: j['note'] as String? ?? '',
  );
}

class SplitGroup {
  const SplitGroup({
    required this.id,
    required this.name,
    required this.members,
    this.kind = 'trip',
    this.defaultShares = const {},
  });

  final String id;
  final String name;
  final String kind;
  final List<GroupMember> members;
  final Map<String, double> defaultShares;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kind': kind,
    'members': members.map((e) => e.toJson()).toList(),
    'defaultShares': defaultShares,
  };

  factory SplitGroup.fromJson(Map<String, dynamic> j) => SplitGroup(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    kind: j['kind'] as String? ?? 'trip',
    members: (j['members'] as List? ?? [])
        .map((e) => GroupMember.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    defaultShares:
        (j['defaultShares'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        ) ??
        const {},
  );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'read': read,
  };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    body: j['body'] as String? ?? '',
    createdAt: DateTime.parse(j['createdAt'] as String),
    read: j['read'] as bool? ?? false,
  );
}

class AppState {
  const AppState({
    this.sessionPhone,
    this.profile,
    this.transactions = const [],
    this.requests = const [],
    this.mandates = const [],
    this.groups = const [],
    this.expenses = const [],
    this.settlements = const [],
    this.notifications = const [],
  });

  final String? sessionPhone;
  final UserProfile? profile;
  final List<TxRecord> transactions;
  final List<PayRequest> requests;
  final List<AutopayMandate> mandates;
  final List<SplitGroup> groups;
  final List<Expense> expenses;
  final List<Settlement> settlements;
  final List<AppNotification> notifications;

  AppState copyWith({
    String? sessionPhone,
    UserProfile? profile,
    List<TxRecord>? transactions,
    List<PayRequest>? requests,
    List<AutopayMandate>? mandates,
    List<SplitGroup>? groups,
    List<Expense>? expenses,
    List<Settlement>? settlements,
    List<AppNotification>? notifications,
    bool clearSession = false,
  }) {
    return AppState(
      sessionPhone: clearSession ? null : (sessionPhone ?? this.sessionPhone),
      profile: clearSession ? null : (profile ?? this.profile),
      transactions: transactions ?? this.transactions,
      requests: requests ?? this.requests,
      mandates: mandates ?? this.mandates,
      groups: groups ?? this.groups,
      expenses: expenses ?? this.expenses,
      settlements: settlements ?? this.settlements,
      notifications: notifications ?? this.notifications,
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionPhone': sessionPhone,
    'profile': profile?.toJson(),
    'transactions': transactions.map((e) => e.toJson()).toList(),
    'requests': requests.map((e) => e.toJson()).toList(),
    'mandates': mandates.map((e) => e.toJson()).toList(),
    'groups': groups.map((e) => e.toJson()).toList(),
    'expenses': expenses.map((e) => e.toJson()).toList(),
    'settlements': settlements.map((e) => e.toJson()).toList(),
    'notifications': notifications.map((e) => e.toJson()).toList(),
  };

  factory AppState.fromJson(Map<String, dynamic> j) => AppState(
    sessionPhone: j['sessionPhone'] as String?,
    profile: j['profile'] == null
        ? null
        : UserProfile.fromJson(Map<String, dynamic>.from(j['profile'] as Map)),
    transactions: (j['transactions'] as List? ?? [])
        .map((e) => TxRecord.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    requests: (j['requests'] as List? ?? [])
        .map((e) => PayRequest.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    mandates: (j['mandates'] as List? ?? [])
        .map(
          (e) => AutopayMandate.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList(),
    groups: (j['groups'] as List? ?? [])
        .map((e) => SplitGroup.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    expenses: (j['expenses'] as List? ?? [])
        .map((e) => Expense.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    settlements: (j['settlements'] as List? ?? [])
        .map((e) => Settlement.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    notifications: (j['notifications'] as List? ?? [])
        .map(
          (e) => AppNotification.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList(),
  );
}
