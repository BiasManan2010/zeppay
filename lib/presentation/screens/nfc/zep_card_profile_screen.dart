import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/chrome.dart';
import '../../../data/models/zep_card.dart';
import '../../../data/services/providers.dart';

/// Profile + live QR revealed by a Zep Card tap (Mode A).
/// Photo is not on the tag — only initials avatar from encoded name.
class ZepCardProfileScreen extends ConsumerStatefulWidget {
  const ZepCardProfileScreen({
    super.key,
    required this.vpa,
    required this.name,
    this.fromNfcTap = false,
  });

  final String vpa;
  final String name;
  final bool fromNfcTap;

  @override
  ConsumerState<ZepCardProfileScreen> createState() =>
      _ZepCardProfileScreenState();
}

class _ZepCardProfileScreenState extends ConsumerState<ZepCardProfileScreen> {
  final _qrKey = GlobalKey();
  var _sharing = false;

  ZepCardProfile get _profile =>
      ZepCardProfile(vpa: widget.vpa, name: widget.name);

  String get _displayName =>
      widget.name.trim().isNotEmpty ? widget.name.trim() : widget.vpa;

  String get _upiUri {
    return Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': widget.vpa,
        'pn': _displayName,
        'cu': 'INR',
      },
    ).toString();
  }

  Future<void> _shareQr() async {
    setState(() => _sharing = true);
    HapticFeedback.mediumImpact();
    try {
      final box =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (box != null) {
        final image = await box.toImage(pixelRatio: 3);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes != null) {
          await Share.shareXFiles(
            [
              XFile.fromData(
                bytes.buffer.asUint8List(),
                name: 'zep-card-qr.png',
                mimeType: 'image/png',
              ),
            ],
            text: 'Pay $_displayName on UPI: ${widget.vpa}',
          );
          return;
        }
      }
      await Share.share('Pay $_displayName on UPI: ${widget.vpa}\n$_upiUri');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _payNow() {
    startPayment(
      ref,
      vpa: widget.vpa,
      amountPaise: 0,
      payeeName: _displayName,
      source: 'zep_card',
    );
    context.push('/pay/amount');
  }

  @override
  Widget build(BuildContext context) {
    final valid = widget.vpa.contains('@');
    return Scaffold(
      
      appBar: AppBar(
        title: Text(widget.fromNfcTap ? 'Zep Card' : 'Profile'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.fromNfcTap)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
              ),
              child: const Text(
                'NFC tap is offline — identity read from the card with zero signal. '
                'Payment still uses *99#/IVR when you tap Pay Now (needs voice signal, not data).',
                style: TextStyle(fontSize: 13),
              ),
            ),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.cardDark,
                  child: Text(
                    _profile.initials,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Initials avatar — photos are not stored on NFC tags',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  _displayName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(widget.vpa, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (!valid)
            const Text('Invalid Zep Card — no UPI ID found on tag.')
          else
            Center(
              child: RepaintBoundary(
                key: _qrKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: QrImageView(
                    data: _upiUri,
                    size: 220,
                    backgroundColor: Colors.white,
                    embeddedImage: null,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: valid
                      ? () async {
                          await Clipboard.setData(
                            ClipboardData(text: widget.vpa),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('UPI ID copied')),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy UPI'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: valid && !_sharing ? _shareQr : null,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(_sharing ? 'Sharing…' : 'Share QR'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GlowButton(
            label: 'PAY NOW',
            onTap: valid ? _payNow : null,
          ),
          const SizedBox(height: 12),
          Text(
            'Zep Card carries identity only — like *99#, it never holds your UPI PIN or balance.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
