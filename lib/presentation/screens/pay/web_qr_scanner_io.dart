import 'package:flutter/material.dart';

/// Native camera preview is web-only.
class WebQrScanner extends StatelessWidget {
  const WebQrScanner({
    super.key,
    required this.onDetect,
    this.onCameraError,
    this.scanWindowKey,
  });

  final ValueChanged<String> onDetect;
  final VoidCallback? onCameraError;
  final GlobalKey? scanWindowKey;

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
