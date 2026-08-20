import 'package:flutter/material.dart';

/// Native camera preview is handled by [MobileScanner] in [ScanScreen].
class WebQrScanner extends StatelessWidget {
  const WebQrScanner({
    super.key,
    required this.onDetect,
    this.onCameraError,
    this.onCameraStarted,
    this.onCameraStopped,
  });

  final ValueChanged<String> onDetect;
  final VoidCallback? onCameraError;
  final VoidCallback? onCameraStarted;
  final VoidCallback? onCameraStopped;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
