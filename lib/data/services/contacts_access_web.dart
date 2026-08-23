import 'phone_contact.dart';

class ContactsAccess {
  static Future<bool> granted() async => false;

  static Future<bool> request() async => false;

  static Future<List<PhoneContact>> load({bool requestIfNeeded = true}) async {
    return const [];
  }

  static String last10(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) return digits.substring(digits.length - 10);
    return digits;
  }
}
