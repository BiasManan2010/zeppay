import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/chrome.dart';
import '../../data/local/app_store.dart';
import '../../data/models/models.dart';

Future<List<GroupMember>> pickGroupMembers(BuildContext context) async {
  if (!await FlutterContacts.requestPermission()) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contacts permission is required')),
      );
    }
    return const [];
  }
  final all = await FlutterContacts.getContacts(withProperties: true);
  final people = all.where((c) => c.phones.isNotEmpty).toList();
  if (!context.mounted) return const [];
  final picked = await showModalBottomSheet<List<GroupMember>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (ctx) => _PickerSheet(people: people),
  );
  return picked ?? const [];
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({required this.people});
  final List<Contact> people;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  final _selected = <String>{};
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.people.where((c) {
      if (_query.isEmpty) return true;
      return c.displayName.toLowerCase().contains(_query.toLowerCase());
    }).toList();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Pick people', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final c = filtered[i];
                  final on = _selected.contains(c.id);
                  return CheckboxListTile(
                    value: on,
                    title: Text(c.displayName),
                    subtitle: Text(c.phones.first.number),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _selected.add(c.id);
                      } else {
                        _selected.remove(c.id);
                      }
                    }),
                  );
                },
              ),
            ),
            GlowButton(
              label: 'ADD ${_selected.length}',
              onTap: () {
                final members = widget.people
                    .where((c) => _selected.contains(c.id))
                    .map((c) {
                      final digits = c.phones.first.number.replaceAll(
                        RegExp(r'\D'),
                        '',
                      );
                      final last10 = digits.length >= 10
                          ? digits.substring(digits.length - 10)
                          : digits;
                      return GroupMember(
                        id: c.id.isEmpty ? AppStore.id() : c.id,
                        name: c.displayName,
                        phone: last10,
                      );
                    })
                    .toList();
                Navigator.pop(context, members);
              },
            ),
          ],
        ),
      ),
    );
  }
}
