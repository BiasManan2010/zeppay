import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'phone_contact.dart';

class ContactsAccess {
  static Future<bool> granted() async {
    return Permission.contacts.isGranted;
  }

  static Future<bool> request() async {
    return FlutterContacts.requestPermission(readonly: true);
  }

  static Future<List<PhoneContact>> load({bool requestIfNeeded = true}) async {
    if (requestIfNeeded) {
      if (!await request()) return const [];
    } else if (!await granted()) {
      return const [];
    }
    try {
      final raw = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      return [
        for (final c in raw)
          PhoneContact(
            id: c.id,
            displayName: c.displayName,
            phones: [for (final p in c.phones) p.number],
          ),
      ];
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
