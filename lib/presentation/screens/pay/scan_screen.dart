import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../data/models/models.dart';
import '../../../data/services/providers.dart';
import '../../../data/services/qr_parser.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  var _locked = false;
  var _amount = '';

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
    var next = draft;
    if (next.amountPaise == 0 && _amount.isNotEmpty) {
      final rupees = double.tryParse(_amount) ?? 0;
      next = PaymentDraft(
        vpa: next.vpa,
        amountPaise: (rupees * 100).round(),
        payeeName: next.payeeName,
        note: next.note,
        source: 'scan',
      );
    }
    if (next.amountPaise <= 0) {
      if (mounted) {
        setState(() => _locked = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR has no amount — enter rupees below, then scan again')),
        );
      }
      return;
    }
    ref.read(paymentDraftProvider.notifier).state = next;
    if (mounted) context.push('/face');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      body: FutureBuilder(
        future: Permission.camera.request(),
        builder: (context, snap) {
          return Stack(
            children: [
              MobileScanner(controller: _controller, onDetect: _onDetect),
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
                          Text('SCAN QR',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(color: AppColors.white)),
                          const Spacer(),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const Spacer(),
                      TextField(
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (v) => _amount = v,
                        style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          hintText: 'Amount if QR has none',
                          filled: true,
                          fillColor: AppColors.base.withValues(alpha: 0.7),
                        ),
                      ),
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
