import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Native `<video>` + jsQR — works on iPhone Safari PWA where Flutter overlays grey out MobileScanner.
class WebQrScanner extends StatefulWidget {
  const WebQrScanner({
    super.key,
    required this.onDetect,
    this.onCameraError,
  });

  final ValueChanged<String> onDetect;
  final VoidCallback? onCameraError;

  @override
  State<WebQrScanner> createState() => _WebQrScannerState();
}

class _WebQrScannerState extends State<WebQrScanner> {
  late final String _viewType;
  html.VideoElement? _video;
  Timer? _timer;
  var _locked = false;
  var _started = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'zep-qr-${DateTime.now().millisecondsSinceEpoch}';
    _register();
    Future<void>.delayed(const Duration(milliseconds: 120), _openCamera);
  }

  void _register() {
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final video = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.backgroundColor = '#000';
      _video = video;
      return video;
    });
  }

  Future<void> _openCamera() async {
    final video = _video;
    if (video == null) return;
    try {
      final media = html.window.navigator.mediaDevices;
      if (media == null) {
        widget.onCameraError?.call();
        return;
      }
      final stream = await media.getUserMedia({
        'video': {
          'facingMode': {'ideal': 'environment'},
        },
        'audio': false,
      });
      video.srcObject = stream;
      await video.play();
      _started = true;
      _timer = Timer.periodic(const Duration(milliseconds: 320), (_) => _scan());
    } catch (_) {
      widget.onCameraError?.call();
    }
  }

  void _scan() {
    if (_locked || !_started) return;
    final video = _video;
    if (video == null) return;
    final w = video.videoWidth;
    final h = video.videoHeight;
    if (w < 2 || h < 2) return;

    final canvas = html.CanvasElement(width: w, height: h);
    canvas.context2D.drawImage(video, 0, 0);
    final imageData = canvas.context2D.getImageData(0, 0, w, h);
    final result = js.context.callMethod('zepDecodeQr', [imageData]);
    if (result == null) return;

    final data = result['data'] as String?;
    if (data == null || data.isEmpty) return;

    _locked = true;
    _timer?.cancel();
    final stream = video.srcObject as html.MediaStream?;
    for (final track in stream?.getTracks() ?? <html.MediaStreamTrack>[]) {
      track.stop();
    }
    widget.onDetect(data);
  }

  @override
  void dispose() {
    _timer?.cancel();
    final stream = _video?.srcObject as html.MediaStream?;
    for (final track in stream?.getTracks() ?? <html.MediaStreamTrack>[]) {
      track.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
