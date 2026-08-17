import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/platform.dart';
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
    with WidgetsBindingObserver {
  final _controller = MobileScannerController(
    autoStart: true,
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 800,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode],
  );
  var _locked = false;
  var _ready = false;
  var _denied = false;
  var _torch = false;
  DateTime _missAt = DateTime.fromMillisecondsSinceEpoch(0);
  PaymentDraft? _hit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prepCamera();
  }

  Future<void> _prepCamera() async {
    if (isWebApp) {
      if (!mounted) return;
      setState(() {
        _denied = false;
        _ready = true;
      });
      unawaited(_safeStart());
      return;
    }
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _denied = !status.isGranted;
      _ready = status.isGranted;
    });
    if (status.isGranted) unawaited(_safeStart());
  }

  Future<void> _safeStart() async {
    try {
      await _controller.start();
    } catch (_) {}
  }

  Future<void> _safeStop() async {
    try {
      await _controller.stop();
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_ready || _locked) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_safeStart());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      unawaited(_safeStop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_safeStop());
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
    await _safeStop();
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    ref.read(paymentDraftProvider.notifier).state = draft;
    await context.push('/pay/amount');
    if (!mounted) return;
    _locked = false;
    _hit = null;
    setState(() {});
    unawaited(_safeStart());
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
    try {
      final cap = await _controller.analyzeImage(shot.path);
      if (!mounted) return;
      if (cap == null || cap.barcodes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not read a QR from that photo. Point the camera at it instead.',
            ),
          ),
        );
        return;
      }
      await _onDetect(cap);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Photo scan is limited here. Use the live camera on this QR.',
          ),
        ),
      );
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      setState(() => _torch = !_torch);
    } catch (_) {}
  }

  Widget _toolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close, color: AppColors.white),
          ),
          const Spacer(),
          Text(
            _locked ? 'LOCKED' : 'SCAN QR',
            style: Theme.of(context)
                .textTheme
                .labelLarge
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
          if (!isWebApp)
            IconButton(
              onPressed: _toggleTorch,
              icon: Icon(
                _torch ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: AppColors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _camera() {
    if (!_ready) {
      return ColoredBox(
        color: AppColors.baseAlt,
        child: Center(
          child: Text(
            _denied
                ? 'Camera permission is off.'
                : 'Starting camera…',
            style: const TextStyle(color: AppColors.white),
          ),
        ),
      );
    }
    return MobileScanner(
      controller: _controller,
      onDetect: _onDetect,
      fit: BoxFit.cover,
      errorBuilder: (context, error) {
        return ColoredBox(
          color: AppColors.baseAlt,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                isWebApp
                    ? 'Allow camera for Zep Pay in Safari, then tap Try again.'
                    : '$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.white),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _hints() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          if (_hit != null)
            MerchantLockCard(name: _hit!.payeeName, vpa: _hit!.vpa)
          else
            Text(
              _denied
                  ? (isWebApp
                      ? 'Safari blocked the camera. Settings → Safari → Camera → Allow, then reopen Zep Pay.'
                      : 'Camera permission is off. Enable it to scan.')
                  : 'Hold the QR in the window. FamPay, GPay, PhonePe, Paytm all work.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.white),
            ),
          if (_denied) ...[
            const SizedBox(height: 12),
            if (!isWebApp)
              TextButton(
                onPressed: openAppSettings,
                child: const Text('OPEN SETTINGS'),
              ),
            TextButton(
              onPressed: _prepCamera,
              child: const Text('TRY AGAIN'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: Column(
          children: [
            _toolbar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _locked
                          ? AppColors.hero
                          : AppColors.hero.withValues(alpha: 0.45),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: isWebApp
                        ? _camera()
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              _camera(),
                              IgnorePointer(
                                child: Center(
                                  child: PaytmScanFrame(
                                    locked: _locked,
                                    t: _locked ? 1 : 0.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            _hints(),
          ],
        ),
      ),
    );
  }
}
