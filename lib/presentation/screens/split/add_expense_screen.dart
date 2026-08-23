import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/models.dart';
import '../../../data/services/fx_service.dart';
import '../../../data/services/ocr_service.dart';
import '../../../data/services/split_math.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, required this.groupId});
  final String groupId;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _tax = TextEditingController();
  final _tip = TextEditingController();
  var _mode = SplitMode.equal;
  var _currency = 'INR';
  var _category = 'food';
  var _fx = 1.0;
  String? _receipt;
  List<LineItem> _items = [];
  final _exact = <String, TextEditingController>{};
  final _pct = <String, TextEditingController>{};
  final _shares = <String, TextEditingController>{};
  final _payers = <String>{'me'};

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _tax.dispose();
    _tip.dispose();
    for (final c in [..._exact.values, ..._pct.values, ..._shares.values]) {
      c.dispose();
    }
    super.dispose();
  }

  SplitGroup? get _group =>
      ref.read(appStoreProvider).groups.where((g) => g.id == widget.groupId).firstOrNull;

  Future<void> _ocr() async {
    final shot = await ImagePicker().pickImage(source: ImageSource.camera);
    if (shot == null) return;
    _receipt = shot.path;
    final items = await OcrService().itemize(shot.path);
    setState(() {
      _items = items;
      _mode = SplitMode.itemized;
      if (items.isNotEmpty) {
        _amount.text = (items.fold<int>(0, (a, b) => a + b.amountPaise) / 100).toStringAsFixed(2);
      }
    });
  }

  Future<void> _save() async {
    final group = _group;
    if (group == null) return;
    final rupees = double.tryParse(_amount.text) ?? 0;
    var total = (rupees * 100).round();
    final tax = ((double.tryParse(_tax.text) ?? 0) * 100).round();
    final tip = ((double.tryParse(_tip.text) ?? 0) * 100).round();
    total += tax + tip;
    if (_currency != 'INR') {
      try {
        _fx = await FxService().convert(amount: 1, from: _currency, to: 'INR');
      } catch (_) {}
    }
    final exact = {for (final m in group.members) m.id: ((double.tryParse(_exact[m.id]?.text ?? '') ?? 0) * 100).round()};
    final pct = {for (final m in group.members) m.id: double.tryParse(_pct[m.id]?.text ?? '') ?? 0};
    final sh = {for (final m in group.members) m.id: double.tryParse(_shares[m.id]?.text ?? '') ?? m.defaultShare};
    final shares = SplitMath.compute(
      mode: _mode,
      totalPaise: total,
      members: group.members,
      exact: exact,
      percents: pct,
      shares: sh,
      items: _items,
    );
    await ref.read(appStoreProvider.notifier).addExpense(
          Expense(
            id: AppStore.id(),
            groupId: widget.groupId,
            title: _title.text.trim().isEmpty ? 'Expense' : _title.text.trim(),
            amountPaise: total,
            createdAt: DateTime.now(),
            payerIds: _payers.toList(),
            shares: shares,
            mode: _mode,
            currency: _currency,
            fxRate: _fx,
            category: _category,
            receiptPath: _receipt,
            items: _items,
            taxPaise: tax,
            tipPaise: tip,
          ),
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final group = _group;
    if (group == null) return const Scaffold(body: SizedBox.shrink());
    for (final m in group.members) {
      _exact.putIfAbsent(m.id, TextEditingController.new);
      _pct.putIfAbsent(m.id, TextEditingController.new);
      _shares.putIfAbsent(
        m.id,
        () => TextEditingController(
          text: '${group.defaultShares[m.id] ?? m.defaultShare}',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add expense')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'TITLE')),
          const SizedBox(height: 8),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'AMOUNT'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'CURRENCY'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _currency,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'INR', child: Text('INR')),
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                        DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                      ],
                      onChanged: (v) => setState(() => _currency = v ?? 'INR'),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'CATEGORY'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _category,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'food', child: Text('Food')),
                        DropdownMenuItem(value: 'travel', child: Text('Travel')),
                        DropdownMenuItem(value: 'stay', child: Text('Stay')),
                        DropdownMenuItem(value: 'utilities', child: Text('Utilities')),
                        DropdownMenuItem(value: 'general', child: Text('General')),
                      ],
                      onChanged: (v) => setState(() => _category = v ?? 'food'),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: TextField(controller: _tax, decoration: const InputDecoration(labelText: 'TAX'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _tip, decoration: const InputDecoration(labelText: 'TIP'))),
            ],
          ),
          const SizedBox(height: 12),
          Text('SPLIT MODE', style: Theme.of(context).textTheme.labelLarge),
          Wrap(
            spacing: 8,
            children: SplitMode.values
                .map((m) => ChoiceChip(
                      label: Text(m.name),
                      selected: _mode == m,
                      onSelected: (_) => setState(() => _mode = m),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          Text('PAYERS', style: Theme.of(context).textTheme.labelLarge),
          Wrap(
            spacing: 8,
            children: group.members
                .map((m) => FilterChip(
                      label: Text(m.name),
                      selected: _payers.contains(m.id),
                      onSelected: (v) => setState(() {
                        if (v) {
                          _payers.add(m.id);
                        } else {
                          _payers.remove(m.id);
                        }
                      }),
                    ))
                .toList(),
          ),
          if (_mode == SplitMode.exact)
            ...group.members.map((m) => TextField(
                  controller: _exact[m.id],
                  decoration: InputDecoration(labelText: '${m.name} amount'),
                  keyboardType: TextInputType.number,
                )),
          if (_mode == SplitMode.percent)
            ...group.members.map((m) => TextField(
                  controller: _pct[m.id],
                  decoration: InputDecoration(labelText: '${m.name} %'),
                  keyboardType: TextInputType.number,
                )),
          if (_mode == SplitMode.shares)
            ...group.members.map((m) => TextField(
                  controller: _shares[m.id],
                  decoration: InputDecoration(labelText: '${m.name} shares'),
                  keyboardType: TextInputType.number,
                )),
          if (_mode == SplitMode.itemized) ...[
            const SizedBox(height: 8),
            ..._items.asMap().entries.map((e) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(e.value.label),
                    trailing: MoneyText(e.value.amountPaise),
                  ),
                  Wrap(
                    spacing: 8,
                    children: group.members
                        .map(
                          (m) => FilterChip(
                            label: Text(m.name),
                            selected: e.value.assigneeIds.contains(m.id),
                            onSelected: (v) {
                              setState(() {
                                final ids = [...e.value.assigneeIds];
                                if (v) {
                                  ids.add(m.id);
                                } else {
                                  ids.remove(m.id);
                                }
                                _items[e.key] = LineItem(
                                  label: e.value.label,
                                  amountPaise: e.value.amountPaise,
                                  assigneeIds: ids,
                                );
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                ],
              );
            }),
          ],
          const SizedBox(height: 12),
          HapticScale(
            onTap: _ocr,
            child: const SurfaceCard(child: Text('Scan receipt (OCR)')),
          ),
          const SizedBox(height: 16),
          HapticScale(
            onTap: _save,
            child: Container(
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.hero, borderRadius: BorderRadius.circular(16)),
              child: const Text('SAVE EXPENSE'),
            ),
          ),
        ],
      ),
    );
  }
}
