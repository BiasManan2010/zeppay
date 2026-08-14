import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/chrome.dart';
import '../../../data/local/app_store.dart';

class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  String _upiUri(String vpa, String name) {
    final am = double.tryParse(_amount.text.trim());
    final tn = Uri.encodeComponent(_note.text.trim());
    final pn = Uri.encodeComponent(name);
    final buf = StringBuffer('upi://pay?pa=$vpa&pn=$pn&cu=INR');
    if (am != null && am > 0) buf.write('&am=${am.toStringAsFixed(2)}');
    if (tn.isNotEmpty) buf.write('&tn=$tn');
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(appStoreProvider).profile;
    final vpa = p?.upiId ?? '';
    final name = p?.name.isNotEmpty == true ? p!.name : 'Zep Pay';
    final uri = vpa.contains('@') ? _upiUri(vpa, name) : '';
    return ZepPage(
      title: 'Receive money',
      subtitle: 'Your UPI QR. Anyone with GPay, PhonePe, or BHIM can scan it.',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (uri.isEmpty)
            const Text('Add a UPI ID in onboarding or Settings first.')
          else
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: QrImageView(
                  data: uri,
                  size: 220,
                  backgroundColor: AppColors.white,
                ),
              ),
            ),
          const SizedBox(height: 16),
          SurfaceCard(
            onTap: vpa.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: vpa));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('UPI ID copied')),
                      );
                    }
                  },
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleMedium),
                      Text(vpa.isEmpty ? 'No UPI ID' : vpa),
                    ],
                  ),
                ),
                const Icon(Icons.copy_rounded, color: AppColors.hero),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'REQUEST AMOUNT (OPTIONAL)'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'NOTE'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          GlowButton(
            label: 'SHARE UPI ID',
            onTap: vpa.isEmpty
                ? null
                : () {
                    final amt = _amount.text.trim();
                    final line = amt.isEmpty
                        ? 'Pay me on UPI: $vpa'
                        : 'Pay ₹$amt to $name on UPI: $vpa';
                    Share.share(line);
                  },
          ),
        ],
      ),
    );
  }
}
