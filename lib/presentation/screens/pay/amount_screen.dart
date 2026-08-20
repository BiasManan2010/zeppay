import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/chrome.dart';
import '../../../data/models/spend_kinds.dart';
import '../../../data/local/app_store.dart';
import '../../../data/local/ux_prefs.dart';
import '../../../data/services/providers.dart';
import '../../../data/services/security_audit.dart';

class AmountScreen extends ConsumerStatefulWidget {
  const AmountScreen({super.key});

  @override
  ConsumerState<AmountScreen> createState() => _AmountScreenState();
}

class _AmountScreenState extends ConsumerState<AmountScreen> {
  var _raw = '';
  final _terms = <double>[];
  var _category = 'food';
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
    final existing = draft?.category ?? '';
    if (existing.isNotEmpty && existing != 'other') {
      _category = existing;
    } else {
      UxPrefs.defaultSpend().then((v) {
        if (mounted) setState(() => _category = v);
      });
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  double get _entryValue => double.tryParse(_raw) ?? 0;

  double get _totalRupees =>
      _terms.fold<double>(0, (a, b) => a + b) + _entryValue;

  int get _paise => (_totalRupees * 100).round();

  String get _breakdown {
    final parts = <String>[
      ..._terms.map(_fmtTerm),
      if (_raw.isNotEmpty) _raw,
    ];
    return parts.join('+');
  }

  String _fmtTerm(double n) {
    if (n == n.roundToDouble()) return n.toStringAsFixed(0);
    return n.toStringAsFixed(2);
  }

  String get _totalLabel {
    if (_paise <= 0) return '₹0';
    final r = _totalRupees;
    if (r == r.roundToDouble()) return '₹${r.toStringAsFixed(0)}';
    return '₹${r.toStringAsFixed(2)}';
  }

  void _plus() {
    HapticFeedback.selectionClick();
    if (_raw.isEmpty) return;
    final n = double.tryParse(_raw);
    if (n == null || n <= 0) return;
    setState(() {
      _terms.add(n);
      _raw = '';
    });
  }

  void _key(String k) {
    if (k == '+') {
      _plus();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      if (k == '⌫') {
        if (_raw.isNotEmpty) {
          _raw = _raw.substring(0, _raw.length - 1);
          return;
        }
        if (_terms.isEmpty) return;
        final last = _terms.removeLast();
        _raw = _fmtTerm(last);
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
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '0', '⌫'];
    return Scaffold(
      appBar: AppBar(title: const Text('Enter amount')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text('Paying $who', style: Theme.of(context).textTheme.titleMedium),
            Text(draft.vpa, style: Theme.of(context).textTheme.bodyMedium),
            if (isWebApp)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'UPI ID copies to clipboard. Phone opens *99*1*3 — paste, amount, PIN.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            const Spacer(),
            AmountTotalDisplay(
              totalLabel: _totalLabel,
              breakdown: _terms.isNotEmpty ? _breakdown : null,
            ),
            if (_paise > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${((_paise / 100) / 100000 * 100).toStringAsFixed(2)}% of a typical ₹1L UPI daily cap',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [100, 200, 500, 1000, 2000]
                  .map(
                    (n) => ActionChip(
                      label: Text('₹$n'),
                      onPressed: () => setState(() {
                        _terms.clear();
                        _raw = '$n';
                      }),
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
                    (k) => GestureDetector(
                      onLongPress: k == '0' ? () => _key('.') : null,
                      child: HapticScale(
                        onTap: () => _key(k),
                        child: Center(
                          child: Text(
                            k,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: k == '+'
                                      ? AppColors.hero
                                      : AppColors.textPrimary,
                                ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: GlowButton(
                label: _paise <= 0 ? 'PAY' : 'PAY ${_totalLabel.replaceFirst('₹', '₹')}',
                onTap: _paise <= 0
                    ? null
                    : () async {
                        ref.read(paymentDraftProvider.notifier).state = draft
                            .copyWith(
                              amountPaise: _paise,
                              note: _note.text.trim(),
                              category: _category,
                            );
                        UxPrefs.saveSpend(_category);
                        if (isWebApp) {
                          final audit =
                              await ref.read(securityAuditProvider.future);
                          final ok = await audit.authorizePayment(
                            amountPaise: _paise,
                            txId: AppStore.id(),
                            vpa: draft.vpa,
                          );
                          if (!ok) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Session expired. Verify OTP again before paying.',
                                ),
                              ),
                            );
                            context.go('/login');
                            return;
                          }
                        }
                        if (!context.mounted) return;
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

/// Snappy Paytm-style pop when the summed total changes.
class AmountTotalDisplay extends StatelessWidget {
  const AmountTotalDisplay({
    super.key,
    required this.totalLabel,
    this.breakdown,
  });

  final String totalLabel;
  final String? breakdown;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(anim),
          child: child,
        ),
      ),
      child: Column(
        key: ValueKey('$totalLabel|$breakdown'),
        children: [
          Text(
            totalLabel,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (breakdown != null && breakdown!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                breakdown!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.heroSoft,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
