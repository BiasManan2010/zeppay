import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/chrome.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/zep_card.dart';
import '../../../data/services/nfc_card_service.dart';

class ZepCardSetupScreen extends ConsumerStatefulWidget {
  const ZepCardSetupScreen({super.key});

  @override
  ConsumerState<ZepCardSetupScreen> createState() => _ZepCardSetupScreenState();
}

class _ZepCardSetupScreenState extends ConsumerState<ZepCardSetupScreen> {
  var _busy = false;
  String _status = '';
  var _nfcOk = false;

  @override
  void initState() {
    super.initState();
    _checkNfc();
  }

  Future<void> _checkNfc() async {
    final ok = await NfcCardService.instance.isAvailable();
    if (mounted) setState(() => _nfcOk = ok);
  }

  Future<void> _write() async {
    final profile = ref.read(appStoreProvider).profile;
    final vpa = profile?.upiId ?? '';
    final name = profile?.name ?? '';
    if (!vpa.contains('@')) {
      setState(() => _status = 'Add your UPI ID in onboarding first.');
      return;
    }
    setState(() {
      _busy = true;
      _status = 'Ready to write…';
    });
    try {
      await NfcCardService.instance.writeZepCard(
        vpa: vpa,
        name: name.isNotEmpty ? name : vpa.split('@').first,
        onStatus: (m) {
          if (mounted) setState(() => _status = m);
        },
      );
      if (mounted) {
        setState(() => _status = 'Zep Card is ready — tap it on any phone with Zep Pay.');
      }
    } catch (e) {
      if (mounted) setState(() => _status = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(appStoreProvider).profile;
    final vpa = profile?.upiId ?? '';
    final name = profile?.name ?? '';
    final preview = vpa.contains('@')
        ? ZepCardProfile(
            vpa: vpa,
            name: name.isNotEmpty ? name : vpa.split('@').first,
          )
        : null;

    return ZepPage(
      title: 'Set up My Zep Card',
      subtitle:
          'Programs a blank NFC card with your VPA + name. Not a bank card — identity only.',
      footer: GlowButton(
        label: _busy ? 'HOLD CARD TO PHONE…' : 'WRITE MY ZEP CARD',
        busy: _busy,
        onTap: !isAndroidDevice || !_nfcOk || _busy ? null : _write,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          if (!isAndroidDevice)
            const Text(
              'Zep Card writing is Android-only. iPhone users can share their QR from Profile.',
            )
          else if (!_nfcOk)
            const Text('NFC is not available on this device.')
          else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.rowLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What gets written (static NDEF, ~200 bytes):',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text('zeppay://profile?vpa=$vpa&name=$name'),
                  const SizedBox(height: 4),
                  Text(
                    ZepCardCodec.webUri(vpa: vpa, name: name).toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (preview != null)
              ListTile(
                leading: CircleAvatar(
                  child: Text(preview.initials),
                ),
                title: Text(preview.name.isNotEmpty ? preview.name : preview.vpa),
                subtitle: Text(preview.vpa),
              ),
            const SizedBox(height: 12),
            const Text(
              'Honest scope: this card cannot pay at bank POS terminals (Pine Labs/EDC). '
              'It works in Zep Pay\'s closed-loop network — tap any phone to reveal profile + pay via *99#.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Issuance idea (pitch): ₹300–500/card with refundable deposit + ZepCoins signup bonus.',
            ),
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(_status, style: const TextStyle(color: AppColors.accent)),
            ],
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.push(
              '/nfc/profile?vpa=${Uri.encodeComponent(vpa)}&name=${Uri.encodeComponent(name)}',
            ),
            child: const Text('Preview my profile screen'),
          ),
        ],
      ),
    );
  }
}
