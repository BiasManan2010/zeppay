import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

/// Read-only address book. Never request WRITE_CONTACTS — it is not in the
/// manifest, so a full contacts permission request fails after the user taps Allow.
class ContactsAccess {
  static Future<bool> granted() async {
    return Permission.contacts.isGranted;
  }

  static Future<bool> request() async {
    return FlutterContacts.requestPermission(readonly: true);
  }

  static Future<List<Contact>> load({bool requestIfNeeded = true}) async {
    if (requestIfNeeded) {
      if (!await request()) return const [];
    } else if (!await granted()) {
      return const [];
    }
    try {
      return await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
    } catch (_) {
      return const [];
    }
  }

  static String last10(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) return digits.substring(digits.length - 10);
    return digits;
  }
}
