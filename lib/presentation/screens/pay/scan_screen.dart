import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../data/services/providers.dart';
import '../../../data/services/qr_parser.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  var _locked = false;
  var _ready = false;
  var _denied = false;

  @override
  void initState() {
    super.initState();
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
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture cap) async {
    if (_locked) return;
    if (cap.barcodes.isEmpty) return;
    final raw = cap.barcodes.first.rawValue;
    if (raw == null) return;
    final draft = QrParser.parse(raw);
    if (draft == null) return;
    _locked = true;
    HapticFeedback.mediumImpact();
    ref.read(paymentDraftProvider.notifier).state = draft;
    if (mounted) {
      await context.push('/pay/amount');
      _locked = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      body: Stack(
        children: [
          if (_ready)
            MobileScanner(controller: _controller, onDetect: _onDetect)
          else
            const ColoredBox(color: AppColors.base),
          Container(color: Colors.black.withValues(alpha: 0.45)),
          const Center(
            child: SizedBox(width: 260, height: 260, child: ScanBrackets()),
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
                        'SCAN QR',
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(color: AppColors.white),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    _denied
                        ? 'Camera permission is off. Enable it to scan.'
                        : 'Point at a UPI QR. Then enter the amount.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.white),
                  ),
                  if (_denied) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () async {
                        await openAppSettings();
                      },
                      child: const Text('OPEN SETTINGS'),
                    ),
                    TextButton(
                      onPressed: _prepCamera,
                      child: const Text('TRY AGAIN'),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
