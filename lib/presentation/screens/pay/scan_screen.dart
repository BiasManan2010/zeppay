import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

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
import 'qr_image_scan.dart';
import 'qr_scan_transition.dart';
import 'scan_lock_overlay.dart';
import 'scan_viewfinder.dart';
import 'web_qr_scanner.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final _scanFrameKey = GlobalKey();
  MobileScannerController? _controller;
  late final AnimationController _scanAnim;

  var _locked = false;
  var _ready = false;
  var _denied = false;
  var _torch = false;
  var _webCameraError = false;
  var _webCameraLive = false;
  var _webScanEpoch = 0;
  DateTime _missAt = DateTime.fromMillisecondsSinceEpoch(0);
  PaymentDraft? _hit;

  static const _frameSize = 284.0;

  @override
  void initState() {
    super.initState();
    _scanAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    if (!isWebApp) {
      _controller = MobileScannerController(
        autoStart: true,
        detectionSpeed: DetectionSpeed.normal,
        detectionTimeoutMs: 800,
        facing: CameraFacing.back,
        formats: const [BarcodeFormat.qrCode],
      );
      WidgetsBinding.instance.addObserver(this);
      unawaited(_prepCamera());
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
    _scanAnim.dispose();
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
    _hit = draft;
    if (!isWebApp) await _safeStop();
    if (!mounted) return;
    _playShatterTransition(draft);
  }

  void _playShatterTransition(PaymentDraft draft) {
    final reduce = MediaQuery.of(context).disableAnimations;
    final frame = _frameFor(context);
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    var navigated = false;

    entry = OverlayEntry(
      builder: (_) => QrScanTransition(
        frameSize: frame,
        reducedMotion: reduce,
        onReveal: () {
          if (navigated || !mounted) return;
          navigated = true;
          ref.read(paymentDraftProvider.notifier).state = draft;
          context.push('/pay/amount');
        },
        onComplete: () {
          entry.remove();
          if (!mounted) return;
          setState(() {
            _locked = false;
            _hit = null;
            _webCameraError = false;
            _webCameraLive = false;
            _webScanEpoch++;
          });
          if (!isWebApp) unawaited(_safeStart());
        },
      ),
    );
    overlay.insert(entry);
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
    try {
      if (isWebApp) {
        final raw = await decodeQrFromGallery(shot);
        if (!mounted) return;
        if (raw == null || raw.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not read a QR from that photo. Point the camera at it instead.',
              ),
            ),
          );
          return;
        }
        await _handleRaw(raw);
        return;
      }
      final ctrl = _controller;
      if (ctrl == null) return;
      final cap = await ctrl.analyzeImage(shot.path);
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

  double _frameFor(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return math.min(_frameSize, w - 48);
  }

  Widget _toolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close_rounded, color: AppColors.white),
          ),
          const Spacer(),
          Text(
            _locked ? 'LOCKED' : 'SCAN & PAY',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.white,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _fromGallery,
            tooltip: 'Gallery',
            icon: const Icon(
              Icons.photo_library_outlined,
              color: AppColors.white,
            ),
          ),
          if (!isWebApp)
            IconButton(
              onPressed: _toggleTorch,
              tooltip: 'Torch',
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
    if (_denied) {
      return const ColoredBox(
        color: AppColors.baseAlt,
        child: Center(
          child: Text(
            'Camera permission is off.',
            style: TextStyle(color: AppColors.white),
          ),
        ),
      );
    }
    if (!_ready) {
      return const ColoredBox(
        color: AppColors.baseAlt,
        child: Center(
          child: Text(
            'Starting camera…',
            style: TextStyle(color: AppColors.white),
          ),
        ),
      );
    }
    return MobileScanner(
      controller: _controller!,
      onDetect: _onDetect,
      fit: BoxFit.cover,
      errorBuilder: (context, error) => ColoredBox(
        color: AppColors.baseAlt,
        child: Center(
          child: Text(
            '$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.white),
          ),
        ),
      ),
    );
  }

  Widget _scanWindow(double frame) {
    final hunting = !_locked;
    final beamOn = hunting && (isWebApp ? _webCameraLive : _ready);
    return AnimatedBuilder(
      animation: _scanAnim,
      builder: (context, _) {
        return SizedBox(
          key: _scanFrameKey,
          width: frame,
          height: frame,
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              if (isWebApp && !_webCameraLive)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0B),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              if (hunting || _locked)
                IgnorePointer(
                  child: ScanViewfinder(
                    t: _scanAnim.value,
                    locked: _locked,
                    showBeam: beamOn,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _bottomHints() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hit != null)
            MerchantLockCard(name: _hit!.payeeName, vpa: _hit!.vpa)
          else
            Text(
              _hintText(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                height: 1.45,
                fontSize: 14,
              ),
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
                  setState(() {
                    _webCameraError = false;
                    _webScanEpoch++;
                  });
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

  String _hintText() {
    if (_denied) {
      return isWebApp
          ? 'Safari blocked the camera. Settings → Safari → Camera → Allow.'
          : 'Camera permission is off. Enable it to scan.';
    }
    if (_webCameraError) {
      return 'Camera blocked. Allow camera access, then tap START CAMERA again.';
    }
    if (isWebApp && !_webCameraLive) {
      return 'Align any UPI QR inside the frame. Tap START CAMERA when ready.';
    }
    return 'Hold a UPI QR steady inside the glowing frame.';
  }

  @override
  Widget build(BuildContext context) {
    final frame = _frameFor(context);

    return Scaffold(
      backgroundColor: AppColors.base,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (!isWebApp) Positioned.fill(child: _nativeCamera()),
          if (!isWebApp)
            Positioned.fill(
              child: IgnorePointer(
                child: ScanDimOverlay(frameSize: frame),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                _toolbar(),
                const Spacer(),
                _scanWindow(frame),
                if (isWebApp)
                  WebQrScanner(
                    key: ValueKey(_webScanEpoch),
                    scanWindowKey: _scanFrameKey,
                    onDetect: _handleRaw,
                    onCameraStarted: () =>
                        setState(() => _webCameraLive = true),
                    onCameraStopped: () =>
                        setState(() => _webCameraLive = false),
                    onCameraError: () => setState(() {
                      _webCameraError = true;
                      _webCameraLive = false;
                    }),
                  ),
                const SizedBox(height: 12),
                const Spacer(),
                _bottomHints(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
