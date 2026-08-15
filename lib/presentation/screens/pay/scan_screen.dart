import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../data/services/providers.dart';
import '../../../data/services/qr_parser.dart';
import 'scan_lock_overlay.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with SingleTickerProviderStateMixin {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 400,
    formats: const [BarcodeFormat.qrCode, BarcodeFormat.dataMatrix],
  );
  late final AnimationController _pulse;
  var _locked = false;
  var _ready = false;
  var _denied = false;
  var _torch = false;
  DateTime _missAt = DateTime.fromMillisecondsSinceEpoch(0);
  PaymentDraft? _hit;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _prepCamera();
  }

  Future<void> _prepCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _denied = !status.isGranted;
      _ready = status.isGranted;
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture cap) async {
    if (_locked) return;
    if (cap.barcodes.isEmpty) return;
    final raw = _payload(cap.barcodes.first);
    if (raw == null || raw.isEmpty) return;
    final draft = QrParser.parse(raw);
    if (draft == null) {
      final now = DateTime.now();
      if (mounted && now.difference(_missAt) > const Duration(seconds: 3)) {
        _missAt = now;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No UPI ID in this QR. Try FamPay / GPay / PhonePe pay QR.',
            ),
          ),
        );
      }
      return;
    }
    _locked = true;
    HapticFeedback.mediumImpact();
    setState(() => _hit = draft);
    _pulse
      ..stop()
      ..duration = const Duration(milliseconds: 520)
      ..forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    ref.read(paymentDraftProvider.notifier).state = draft;
    await context.push('/pay/amount');
    if (!mounted) return;
    _locked = false;
    _hit = null;
    _pulse
      ..duration = const Duration(milliseconds: 1400)
      ..repeat();
    setState(() {});
  }

  String? _payload(Barcode b) {
    final raw = b.rawValue?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    final shown = b.displayValue?.trim();
    if (shown != null && shown.isNotEmpty) return shown;
    final decoded = b.rawDecodedBytes;
    final bytes = switch (decoded) {
      DecodedBarcodeBytes(:final bytes) => bytes,
      DecodedVisionBarcodeBytes(:final bytes, :final rawBytes) =>
        bytes ?? rawBytes,
      _ => null,
    };
    if (bytes == null || bytes.isEmpty) return null;
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return null;
    }
  }

  Future<void> _fromGallery() async {
    final shot = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (shot == null) return;
    final cap = await _controller.analyzeImage(shot.path);
    if (!mounted) return;
    if (cap == null || cap.barcodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read a QR from that photo.')),
      );
      return;
    }
    await _onDetect(cap);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      body: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          return Stack(
            children: [
              if (_ready)
                MobileScanner(controller: _controller, onDetect: _onDetect)
              else
                const ColoredBox(color: AppColors.base),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 1.05,
                    colors: [
                      Colors.transparent,
                      AppColors.base.withValues(alpha: _locked ? 0.55 : 0.38),
                    ],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
              Center(
                child: PaytmScanFrame(
                  locked: _locked,
                  t: _pulse.value,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.close, color: AppColors.white),
                          ),
                          const Spacer(),
                          Text(
                            _locked ? 'LOCKED' : 'SCAN QR',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: AppColors.white),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _fromGallery,
                            icon: const Icon(
                              Icons.photo_library_outlined,
                              color: AppColors.white,
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await _controller.toggleTorch();
                              setState(() => _torch = !_torch);
                            },
                            icon: Icon(
                              _torch
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (_hit != null)
                        MerchantLockCard(
                          name: _hit!.payeeName,
                          vpa: _hit!.vpa,
                        )
                      else
                        Text(
                          _denied
                              ? 'Camera permission is off. Enable it to scan.'
                              : 'Hold steady. FamPay, GPay, PhonePe, Paytm QRs all work.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.white),
                        ),
                      if (_denied) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: openAppSettings,
                          child: const Text('OPEN SETTINGS'),
                        ),
                        TextButton(
                          onPressed: _prepCamera,
                          child: const Text('TRY AGAIN'),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
