import 'package:flutter_test/flutter_test.dart';
import 'package:zeppay/data/services/payment_verification.dart';
import 'package:zeppay/data/services/payment_status_detector.dart';
import 'package:zeppay/data/services/payment_tracker.dart';
import 'package:zeppay/data/services/qr_parser.dart';
import 'package:zeppay/data/services/split_math.dart';
import 'package:zeppay/data/local/app_store.dart';
import 'package:zeppay/data/models/models.dart';
import 'package:zeppay/data/services/csv_export_service.dart';
import 'package:zeppay/data/services/ocr_service.dart';
import 'package:zeppay/data/models/zep_card.dart';
import 'package:zeppay/data/services/rail_engine.dart';
import 'package:zeppay/data/services/telephony_service.dart';

void main() {
  test('parses NPCI UPI QR locally', () {
    final draft = QrParser.parse(
      'upi://pay?pa=merchant@okicici&pn=Tea%20Stall&am=120.50&cu=INR&tn=chai',
    );
    expect(draft, isNotNull);
    expect(draft!.vpa, 'merchant@okicici');
    expect(draft.amountPaise, 12050);
    expect(draft.payeeName, 'Tea Stall');
  });

  test('parses uppercase UPI params and ignores merchant name as VPA', () {
    final draft = QrParser.parse(
      'UPI://PAY?PA=shop@ybl&PN=Tea%20Stall&AM=10',
    );
    expect(draft!.vpa, 'shop@ybl');
    expect(draft.amountPaise, 1000);
    expect(draft.payeeName, 'Tea Stall');
  });

  test('parses UPI QR embedded in extra text with no amount', () {
    final draft = QrParser.parse(
      '000201 extra upi://pay?pa=me@okaxis&pn=Me',
    );
    expect(draft!.vpa, 'me@okaxis');
    expect(draft.amountPaise, 0);
  });

  test('rejects UPI QR with no pa', () {
    expect(QrParser.parse('upi://pay?pn=OnlyName'), isNull);
  });

  test('parses FamPay UPI intent', () {
    final draft = QrParser.parse(
      'upi://pay?pa=manan@yesfam&pn=Manan%20Shah&cu=INR&mc=0000',
    );
    expect(draft!.vpa, 'manan@yesfam');
    expect(draft.payeeName, 'Manan Shah');
  });

  test('parses FamPay-style Bharat QR EMV with nested VPA', () {
    const inner = '0014A00000052410100112shop@yesfam';
    final emv =
        '00020101021126${inner.length.toString().padLeft(2, '0')}$inner'
        '5204000053033565802IN5912Fam Merchant6304ABCD';
    final draft = QrParser.parse(emv);
    expect(draft, isNotNull);
    expect(draft!.vpa, 'shop@yesfam');
    expect(draft.payeeName, 'Fam Merchant');
  });

  test('parses Android intent wrapper used by some FamPay QRs', () {
    final draft = QrParser.parse(
      'intent://pay?pa=user@fbl&pn=Fam&am=50#Intent;scheme=upi;end',
    );
    expect(draft!.vpa, 'user@fbl');
    expect(draft.amountPaise, 5000);
  });

  test('parses HTTPS pay link with pa', () {
    final draft = QrParser.parse(
      'https://fampay.in/pay?pa=tea@yesfam&pn=Tea&am=12',
    );
    expect(draft!.vpa, 'tea@yesfam');
    expect(draft.amountPaise, 1200);
  });

  test('equal split remainder goes to first member', () {
    final members = [
      const GroupMember(id: 'a', name: 'A'),
      const GroupMember(id: 'b', name: 'B'),
      const GroupMember(id: 'c', name: 'C'),
    ];
    final shares = SplitMath.compute(
      mode: SplitMode.equal,
      totalPaise: 100,
      members: members,
    );
    expect(shares.fold<int>(0, (a, b) => a + b.amountPaise), 100);
  });

  test('debt simplification reduces to min transfers', () {
    final members = [
      const GroupMember(id: 'a', name: 'A'),
      const GroupMember(id: 'b', name: 'B'),
      const GroupMember(id: 'c', name: 'C'),
    ];
    final expenses = [
      Expense(
        id: '1',
        groupId: 'g',
        title: 'x',
        amountPaise: 300,
        createdAt: DateTime(2026, 1, 1),
        payerIds: const ['a'],
        shares: const [
          ExpenseShare(memberId: 'a', amountPaise: 100),
          ExpenseShare(memberId: 'b', amountPaise: 100),
          ExpenseShare(memberId: 'c', amountPaise: 100),
        ],
      ),
    ];
    final edges = SplitMath.simplify(
      members: members,
      expenses: expenses,
      settlements: const [],
    );
    expect(edges.length, 2);
    expect(edges.fold<int>(0, (a, e) => a + e.amount), 200);
  });

  test('OCR line parser extracts amounts', () {
    final items = OcrService.parseLines(
      'Masala dosa  ₹120.00\nFilter coffee 40',
    );
    expect(items.length, 2);
    expect(items.first.label.toLowerCase(), contains('dosa'));
  });

  test('Jio is routed to 123PAY IVR', () {
    const info = NetworkInfo(
      operator: 'Jio',
      isJio: true,
      networkType: 'lte',
      recommendedRail: 'ivr',
      ussdSupported: false,
      platform: 'android',
    );
    expect(RailEngine.resolve(info).rail, PaymentRail.ivr);
  });

  test('Android resolve never returns upiIntent', () {
    const info = NetworkInfo(
      operator: 'Airtel',
      isJio: false,
      networkType: 'lte',
      recommendedRail: 'ussd',
      ussdSupported: true,
      platform: 'android',
    );
    expect(RailEngine.resolve(info).rail, isNot(PaymentRail.upiIntent));

    const jio = NetworkInfo(
      operator: 'Jio',
      isJio: true,
      networkType: 'lte',
      recommendedRail: 'ivr',
      ussdSupported: false,
      platform: 'android',
    );
    expect(RailEngine.resolve(jio).rail, isNot(PaymentRail.upiIntent));
  });

  test('unknown platform returns error not upiIntent on Android path', () {
    final r = RailEngine.resolve(NetworkInfo.unknown());
    expect(r.rail, isNull);
    expect(r.error, isNotNull);
  });

  test('USSD embeds full amount for large values', () {
    const draft = PaymentDraft(
      vpa: 'merchant@okicici',
      amountPaise: 123456789,
      payeeName: 'Big',
    );
    final dial = RailEngine.ussdString(
      vpa: draft.vpa,
      amountPaise: draft.amountPaise,
    );
    expect(dial, contains('*1234568#'));
    expect(dial, isNot(contains('*1234567#')));
  });

  test('123PAY dial uses semicolon wait on default OEMs', () {
    const draft = PaymentDraft(
      vpa: 'tea@okicici',
      amountPaise: 15000,
      payeeName: 'Tea',
    );
    expect(RailEngine.ivrString(draft), '18008913333;150');
    expect(RailEngine.ivrString(draft, manufacturer: 'samsung'),
        '18008913333,,,150');
  });

  test('balance enquiry uses NPCI *99*3#', () {
    expect(RailEngine.balanceUssd, '*99*3#');
  });

  test('CSV ledger names members instead of ids', () {
    const group = SplitGroup(
      id: 'g',
      name: 'Goa',
      members: [
        GroupMember(id: 'me', name: 'You'),
        GroupMember(id: 'riya', name: 'Riya'),
      ],
    );
    final csv = CsvExportService().exportGroup(
      group: group,
      expenses: [
        Expense(
          id: '1',
          groupId: 'g',
          title: 'Taxi',
          amountPaise: 50000,
          createdAt: DateTime(2026, 1, 1),
          payerIds: const ['me'],
          shares: const [],
        ),
      ],
      settlements: const [],
    );
    expect(csv, contains('Taxi'));
    expect(csv, contains('You'));
    expect(csv, isNot(contains('me|')));
  });

  test('local payment refs are ZP-prefixed', () {
    expect(AppStore.payRef(), startsWith('ZP'));
  });

  test('dialer timing never marks two-minute idle as success', () {
    expect(detectPaymentStatus(const Duration(seconds: 5)), TxStatus.failed);
    expect(detectPaymentStatus(const Duration(seconds: 45)), TxStatus.success);
    expect(detectPaymentStatus(const Duration(seconds: 120)), TxStatus.pending);
    expect(detectPaymentStatus(const Duration(seconds: 150)), TxStatus.failed);
  });

  test('user USSD outcome maps to ledger status', () {
    expect(
      statusFromUserOutcome(UssdUserOutcome.success),
      TxStatus.success,
    );
    expect(
      statusFromUserOutcome(UssdUserOutcome.noDial),
      TxStatus.failed,
    );
    expect(
      statusFromUserOutcome(UssdUserOutcome.pending),
      TxStatus.pending,
    );
    expect(
      canConfirmSuccess(
        outcome: UssdUserOutcome.success,
        amountMatches: true,
      ),
      isTrue,
    );
    expect(
      canConfirmSuccess(
        outcome: UssdUserOutcome.success,
        amountMatches: false,
      ),
      isFalse,
    );
  });

  test('payment tracker steps follow USSD flow order', () {
    final track = PaymentTrack(
      txId: '1',
      refCode: 'ZP1',
      vpa: 'shop@upi',
      amountPaise: 5000,
      startedAt: DateTime.now(),
      phase: PaymentTrackPhase.awaitingConfirm,
      longestPhoneStint: const Duration(seconds: 42),
      userOutcome: UssdUserOutcome.success,
    );
    final steps = trackSteps(track);
    expect(steps.length, 4);
    expect(steps.last.label, 'You confirm');
    expect(steps[2].state, PaymentTrackStepState.done);
  });

  test('tx json keeps spending category', () {
    final tx = TxRecord(
      id: '1',
      vpa: 'a@upi',
      amountPaise: 100,
      status: TxStatus.pending,
      createdAt: DateTime(2026, 1, 1),
      category: 'food',
    );
    expect(TxRecord.fromJson(tx.toJson()).category, 'food');
  });

  test('Zep Card codec round-trips profile URIs', () {
    const profile = ZepCardProfile(vpa: 'rahul@upi', name: 'Rahul Shah');
    final app = ZepCardCodec.appUri(vpa: profile.vpa, name: profile.name);
    final web = ZepCardCodec.webUri(vpa: profile.vpa, name: profile.name);
    expect(ZepCardCodec.parseUri(app)?.vpa, profile.vpa);
    expect(ZepCardCodec.parseUri(app)?.name, profile.name);
    expect(ZepCardCodec.parseUri(web)?.vpa, profile.vpa);
    expect(profile.initials, 'RS');
  });
}
