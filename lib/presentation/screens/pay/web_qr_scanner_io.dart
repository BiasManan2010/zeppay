import 'package:flutter/material.dart';

/// Native camera preview is handled by [MobileScanner] in [ScanScreen].
class WebQrScanner extends StatelessWidget {
  const WebQrScanner({
    super.key,
    required this.onDetect,
    this.onCameraError,
    this.onCameraStarted,
    this.onCameraStopped,
    this.scanWindowKey,
  });

  final ValueChanged<String> onDetect;
  final VoidCallback? onCameraError;
  final VoidCallback? onCameraStarted;
  final VoidCallback? onCameraStopped;
  final GlobalKey? scanWindowKey;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
