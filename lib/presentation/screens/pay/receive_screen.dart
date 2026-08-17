import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/chrome.dart';
import '../../../core/widgets/illustrations.dart';
import '../../../data/local/app_store.dart';

class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _qrKey = GlobalKey();
  var _sharing = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  String _upiUri(String vpa, String name) {
    final am = double.tryParse(_amount.text.trim());
    final pn = Uri.encodeComponent(name);
    final buf = StringBuffer('upi://pay?pa=$vpa&pn=$pn&cu=INR');
    if (am != null && am > 0) buf.write('&am=${am.toStringAsFixed(2)}');
    final tn = _note.text.trim();
    if (tn.isNotEmpty) buf.write('&tn=${Uri.encodeComponent(tn)}');
    return buf.toString();
  }

  Future<void> _share(String vpa, String name, String uri) async {
    setState(() => _sharing = true);
    HapticFeedback.mediumImpact();
    try {
      final box = _qrKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (box != null) {
        final image = await box.toImage(pixelRatio: 3);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes != null) {
          final png = bytes.buffer.asUint8List();
          final amt = _amount.text.trim();
          final line = amt.isEmpty
              ? 'Pay $name on UPI: $vpa'
              : 'Pay ₹$amt to $name on UPI: $vpa';
          await Share.shareXFiles(
            [
              XFile.fromData(
                png,
                name: 'zeppay-qr.png',
                mimeType: 'image/png',
              ),
            ],
            text: line,
          );
          return;
        }
      }
      await Share.share('Pay $name on UPI: $vpa\n$uri');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(appStoreProvider).profile;
    final vpa = p?.upiId ?? '';
    final name = p?.name.isNotEmpty == true ? p!.name : 'Zep Pay';
    final uri = vpa.contains('@') ? _upiUri(vpa, name) : '';
    return ZepPage(
      title: 'My QR',
      subtitle: 'Share this so someone can pay you.',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (uri.isEmpty)
            const EmptyScene(
              art: ZepArt.receive,
              message: 'Add a UPI ID in onboarding first.',
              size: 148,
            )
          else
            Center(
              child: RepaintBoundary(
                key: _qrKey,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: uri,
                        size: 220,
                        backgroundColor: AppColors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        vpa,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          SurfaceCard(
            onTap: vpa.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: vpa));
                    HapticFeedback.selectionClick();
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
            decoration: const InputDecoration(labelText: 'AMOUNT (OPTIONAL)'),
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
            label: 'SHARE QR',
            busy: _sharing,
            onTap: vpa.isEmpty || uri.isEmpty
                ? null
                : () => _share(vpa, name, uri),
          ),
        ],
      ),
    );
  }
}
