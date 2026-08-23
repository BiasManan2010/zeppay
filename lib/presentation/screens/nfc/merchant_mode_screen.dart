import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/platform.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/zep_card.dart';
import '../../../data/services/nfc_card_service.dart';
import '../../../data/services/sound_cue_service.dart';

/// Mode B — merchant tablet listens for Zep Cards and collects payment.
class MerchantModeScreen extends ConsumerStatefulWidget {
  const MerchantModeScreen({super.key});

  @override
  ConsumerState<MerchantModeScreen> createState() => _MerchantModeScreenState();
}

class _MerchantModeScreenState extends ConsumerState<MerchantModeScreen> {
  final _amount = TextEditingController(text: '100');
  var _listening = false;
  var _nfcOk = false;
  ZepCardProfile? _lastTap;
  String _status = 'Enter amount, then start listening';

  @override
  void initState() {
    super.initState();
    _checkNfc();
  }

  @override
  void dispose() {
    NfcCardService.instance.stopListening();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _checkNfc() async {
    final ok = await NfcCardService.instance.isAvailable();
    if (mounted) setState(() => _nfcOk = ok);
  }

  String get _merchantVpa => ref.read(appStoreProvider).profile?.upiId ?? '';

  String get _merchantName =>
      ref.read(appStoreProvider).profile?.name ?? 'Merchant';

  int get _amountPaise {
    final rupees = double.tryParse(_amount.text.trim()) ?? 0;
    return (rupees * 100).round();
  }

  String _receiveUri(int amountPaise) {
    final am = (amountPaise / 100).toStringAsFixed(2);
    return Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': _merchantVpa,
        'pn': _merchantName,
        'am': am,
        'cu': 'INR',
        'tn': 'Zep Card',
      },
    ).toString();
  }

  Future<void> _onCardTapped(ZepCardProfile profile) async {
    await NfcCardService.instance.stopListening();
    final amount = _amountPaise;
    if (amount <= 0 || !_merchantVpa.contains('@')) {
      setState(() => _status = 'Set merchant UPI ID and amount first');
      return;
    }
    HapticFeedback.heavyImpact();
    await SoundCueService().success();

    if (!mounted) return;
    setState(() {
      _listening = false;
      _lastTap = profile;
      _status =
          '${profile.name.isNotEmpty ? profile.name : profile.vpa} tapped — ask them to pay ₹${(amount / 100).toStringAsFixed(0)}';
    });
  }

  Future<void> _toggleListen() async {
    if (_listening) {
      await NfcCardService.instance.stopListening();
      setState(() {
        _listening = false;
        _status = 'Listening stopped';
      });
      return;
    }
    if (!_nfcOk) {
      setState(() => _status = 'NFC not available');
      return;
    }
    if (_amountPaise <= 0) {
      setState(() => _status = 'Enter a valid amount');
      return;
    }
    setState(() {
      _listening = true;
      _lastTap = null;
      _status = 'Tap Zep Card on this device…';
    });
    await NfcCardService.instance.startListening(
      _onCardTapped,
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _listening = false;
          _status = e.toString();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = _amountPaise;
    final uri = _merchantVpa.contains('@') && amount > 0
        ? _receiveUri(amount)
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Merchant Terminal'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                '₹${amount > 0 ? (amount / 100).toStringAsFixed(0) : '—'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextField(
                controller: _amount,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  labelStyle: const TextStyle(color: Colors.white54),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GestureDetector(
                  onTap: _toggleListen,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _listening
                          ? AppColors.accent.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.06),
                      border: Border.all(
                        color: _listening ? AppColors.accent : Colors.white24,
                        width: 3,
                      ),
                      boxShadow: _listening
                          ? [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.35),
                                blurRadius: 32,
                                spreadRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.nfc_rounded,
                          size: 72,
                          color: _listening ? AppColors.accent : Colors.white54,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _listening ? 'Listening…' : 'Tap to Pay',
                          style: TextStyle(
                            color: _listening ? AppColors.accent : Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _status,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white60),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_lastTap != null && uri.isNotEmpty) ...[
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 48),
                Text(
                  'Customer: ${_lastTap!.name.isNotEmpty ? _lastTap!.name : _lastTap!.vpa}',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(data: uri, size: 160),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Customer scans on their phone → pays via *99#/IVR',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
              if (!isAndroidDevice)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Merchant mode requires Android NFC',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
