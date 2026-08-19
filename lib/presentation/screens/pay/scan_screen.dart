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
import 'qr_scan_transition.dart';
import 'web_qr_scanner.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _controller;
  var _locked = false;
  var _ready = false;
  var _denied = false;
  var _torch = false;
  var _webCameraError = false;
  var _shatter = false;
  DateTime _missAt = DateTime.fromMillisecondsSinceEpoch(0);
  PaymentDraft? _hit;

  @override
  void initState() {
    super.initState();
    if (!isWebApp) {
      _controller = MobileScannerController(
        autoStart: true,
        detectionSpeed: DetectionSpeed.normal,
        detectionTimeoutMs: 800,
        facing: CameraFacing.back,
        formats: const [BarcodeFormat.qrCode],
      );
      WidgetsBinding.instance.addObserver(this);
      _prepCamera();
    } else {
      _ready = true;
    }
  }

  Future<void> _prepCamera() async {
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
      await _controller?.start();
    } catch (_) {}
  }

  Future<void> _safeStop() async {
    try {
      await _controller?.stop();
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (isWebApp || !_ready || _locked) return;
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
    if (!isWebApp) {
      WidgetsBinding.instance.removeObserver(this);
      unawaited(_safeStop());
      _controller?.dispose();
    }
    super.dispose();
  }

  Future<void> _handleRaw(String raw) async {
    if (_locked) return;
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
    await Clipboard.setData(ClipboardData(text: draft.vpa));
    setState(() {
      _hit = draft;
      _shatter = true;
    });
    if (!isWebApp) await _safeStop();
  }

  Future<void> _afterShatter() async {
    if (!mounted) return;
    final draft = _hit;
    if (draft == null) return;
    ref.read(paymentDraftProvider.notifier).state = draft;
    await context.push('/pay/amount');
    if (!mounted) return;
    _locked = false;
    _hit = null;
    _shatter = false;
    _webCameraError = false;
    setState(() {});
    if (!isWebApp) unawaited(_safeStart());
  }

  Future<void> _onDetect(BarcodeCapture cap) async {
    if (cap.barcodes.isEmpty) return;
    final raw = _payload(cap.barcodes.first);
    if (raw == null || raw.isEmpty) return;
    await _handleRaw(raw);
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
    final ctrl = isWebApp ? MobileScannerController() : _controller;
    if (ctrl == null) return;
    try {
      final cap = await ctrl.analyzeImage(shot.path);
      if (isWebApp) await ctrl.dispose();
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
      if (isWebApp) await ctrl.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo scan failed. Use the live camera.')),
      );
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller?.toggleTorch();
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

  Widget _nativeCamera() {
    if (!_ready) {
      return ColoredBox(
        color: AppColors.baseAlt,
        child: Center(
          child: Text(
            _denied ? 'Camera permission is off.' : 'Starting camera…',
            style: const TextStyle(color: AppColors.white),
          ),
        ),
      );
    }
    return MobileScanner(
      controller: _controller!,
      onDetect: _onDetect,
      fit: BoxFit.cover,
      errorBuilder: (context, error) {
        return ColoredBox(
          color: AppColors.baseAlt,
          child: Center(
            child: Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _webCamera() {
    if (_webCameraError) {
      return ColoredBox(
        color: AppColors.baseAlt,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Allow Camera for this site in Safari Settings, then tap Try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.white),
            ),
          ),
        ),
      );
    }
    return WebQrScanner(
      onDetect: _handleRaw,
      onCameraError: () => setState(() => _webCameraError = true),
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
              _denied || _webCameraError
                  ? (isWebApp
                      ? 'Safari blocked the camera. Settings → Safari → Camera → Allow, then reopen Zep Pay.'
                      : 'Camera permission is off. Enable it to scan.')
                  : 'UPI ID copies on lock. Then amount, then Phone (*99*1*3).',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.white),
            ),
          if (_denied || _webCameraError) ...[
            const SizedBox(height: 12),
            if (!isWebApp)
              TextButton(
                onPressed: openAppSettings,
                child: const Text('OPEN SETTINGS'),
              ),
            TextButton(
              onPressed: () {
                if (isWebApp) {
                  setState(() => _webCameraError = false);
                } else {
                  _prepCamera();
                }
              },
              child: const Text('TRY AGAIN'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: isWebApp ? _webCamera() : _nativeCamera(),
          ),
          const Positioned.fill(
            child: IgnorePointer(child: ScanIdleFrame()),
          ),
          SafeArea(
            child: Column(
              children: [
                _toolbar(),
                const Spacer(),
                _hints(),
              ],
            ),
          ),
          if (_shatter)
            Positioned.fill(
              child: QrScanTransition(
                reducedMotion: reduce,
                onComplete: () {
                  unawaited(_afterShatter());
                },
              ),
            ),
        ],
      ),
    );
  }
}
