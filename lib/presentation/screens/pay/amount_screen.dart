import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/app_motion.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/chrome.dart';
import '../../../data/models/spend_kinds.dart';
import '../../../data/services/providers.dart';

class AmountScreen extends ConsumerStatefulWidget {
  const AmountScreen({super.key});

  @override
  ConsumerState<AmountScreen> createState() => _AmountScreenState();
}

class _AmountScreenState extends ConsumerState<AmountScreen> {
  var _raw = '';
  var _category = 'other';
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    final draft = ref.read(paymentDraftProvider);
    if (draft != null && draft.amountPaise > 0) {
      final rupees = draft.amountPaise / 100;
      _raw = rupees == rupees.roundToDouble()
          ? rupees.toStringAsFixed(0)
          : rupees.toStringAsFixed(2);
    }
    _note.text = draft?.note ?? '';
    _category = draft?.category ?? 'other';
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  int get _paise {
    final n = double.tryParse(_raw);
    if (n == null) return 0;
    return (n * 100).round();
  }

  void _key(String k) {
    HapticFeedback.selectionClick();
    setState(() {
      if (k == '⌫') {
        if (_raw.isNotEmpty) _raw = _raw.substring(0, _raw.length - 1);
        return;
      }
      if (k == '.' && _raw.contains('.')) return;
      if (_raw.contains('.') && _raw.split('.').last.length >= 2) return;
      if (_raw.length > 9) return;
      _raw += k;
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(paymentDraftProvider);
    if (draft == null) {
      return const Scaffold(body: Center(child: Text('No payee selected')));
    }
    final who = draft.payeeName.isEmpty ? draft.vpa : draft.payeeName;
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '⌫'];
    return Scaffold(
      appBar: AppBar(title: const Text('Enter amount')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text('Paying $who', style: Theme.of(context).textTheme.titleMedium),
            Text(draft.vpa, style: Theme.of(context).textTheme.bodyMedium),
            const Spacer(),
            SoftSwitcher(
              child: Text(
                _raw.isEmpty ? '₹0' : '₹$_raw',
                key: ValueKey(_raw),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [100, 200, 500, 1000, 2000]
                  .map(
                    (n) => ActionChip(
                      label: Text('₹$n'),
                      onPressed: () => setState(() => _raw = '$n'),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                child: Text(
                  'SPENDING ON',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: SpendKinds.all.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final k = SpendKinds.all[i];
                  final on = _category == k.id;
                  return ChoiceChip(
                    selected: on,
                    avatar: Icon(k.icon, size: 16),
                    label: Text(k.label),
                    onSelected: (_) => setState(() => _category = k.id),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: TextField(
                controller: _note,
                decoration: const InputDecoration(labelText: 'NOTE (OPTIONAL)'),
              ),
            ),
            const Spacer(),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1.85,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: keys
                  .map(
                    (k) => HapticScale(
                      onTap: () => _key(k),
                      child: Center(
                        child: Text(
                          k,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: GlowButton(
                label: _paise <= 0 ? 'PAY' : 'PAY ₹$_raw',
                onTap: _paise <= 0
                    ? null
                    : () {
                        ref.read(paymentDraftProvider.notifier).state = draft
                            .copyWith(
                              amountPaise: _paise,
                              note: _note.text.trim(),
                              category: _category,
                            );
                        context.push('/connecting');
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
