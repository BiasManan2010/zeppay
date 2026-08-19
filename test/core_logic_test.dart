import 'package:flutter_test/flutter_test.dart';
import 'package:zeppay/data/services/payment_status_detector.dart';
import 'package:zeppay/data/services/qr_parser.dart';
import 'package:zeppay/data/services/split_math.dart';
import 'package:zeppay/data/local/app_store.dart';
import 'package:zeppay/data/models/models.dart';
import 'package:zeppay/data/services/csv_export_service.dart';
import 'package:zeppay/data/services/ocr_service.dart';
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
    expect(RailEngine.select(info), PaymentRail.ivr);
  });

  test('123PAY dial string includes amount DTMF', () {
    const draft = PaymentDraft(
      vpa: 'tea@okicici',
      amountPaise: 15000,
      payeeName: 'Tea',
    );
    expect(RailEngine.ivrString(draft), contains('150'));
    expect(RailEngine.ivrScript(draft).toLowerCase(), contains('tea@okicici'));
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
}
