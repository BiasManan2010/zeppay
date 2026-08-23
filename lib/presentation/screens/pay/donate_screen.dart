import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../data/services/providers.dart';

/// Fixed donation causes — payments use the existing offline USSD/IVR rail.
class DonationCause {
  const DonationCause({
    required this.id,
    required this.name,
    required this.vpa,
    required this.description,
  });

  final String id;
  final String name;
  final String vpa;
  final String description;
}

const donationCauses = <DonationCause>[
  DonationCause(
    id: 'relief',
    name: 'Community Relief Fund',
    vpa: 'zeppay.relief@ibl',
    description: 'Food & medical kits for affected families',
  ),
  DonationCause(
    id: 'education',
    name: 'Rural Education Drive',
    vpa: 'zeppay.education@ibl',
    description: 'Tablets & connectivity for village schools',
  ),
  DonationCause(
    id: 'health',
    name: 'Public Health Initiative',
    vpa: 'zeppay.health@ibl',
    description: 'Vaccination camps & essential supplies',
  ),
];

class DonateScreen extends ConsumerStatefulWidget {
  const DonateScreen({super.key});

  @override
  ConsumerState<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends ConsumerState<DonateScreen> {
  DonationCause _cause = donationCauses.first;
  final _amountCtrl = TextEditingController();
  final _presets = const [50, 100, 250, 500];

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  int? _paise() {
    final n = double.tryParse(_amountCtrl.text.trim());
    if (n == null || n <= 0) return null;
    return (n * 100).round();
  }

  void _donate() {
    final paise = _paise();
    if (paise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    startPayment(
      ref,
      vpa: _cause.vpa,
      amountPaise: paise,
      payeeName: _cause.name,
      note: 'Donation — ${_cause.name}',
      source: 'donate',
      category: 'donation',
    );
    context.push('/pay/amount');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Donate'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Give offline',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Donations go through the same *99# / 123PAY rail as any payment — no internet required once you start.',
                  style: TextStyle(color: AppColors.textOnCreamMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Choose a cause', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...donationCauses.map(
            (c) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: _cause.id == c.id
                  ? AppColors.accent.withValues(alpha: 0.12)
                  : null,
              child: RadioListTile<String>(
                value: c.id,
                groupValue: _cause.id,
                activeColor: AppColors.accent,
                onChanged: (id) {
                  setState(() {
                    _cause = donationCauses.firstWhere((x) => x.id == id);
                  });
                },
                title: Text(c.name),
                subtitle: Text(c.description),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Amount (₹)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Enter amount',
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _presets.map((p) {
              return ActionChip(
                label: Text('₹$p'),
                onPressed: () => _amountCtrl.text = '$p',
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              minimumSize: const Size(double.infinity, 52),
            ),
            onPressed: _donate,
            child: const Text('Donate via offline rail'),
          ),
        ],
      ),
    );
  }
}
