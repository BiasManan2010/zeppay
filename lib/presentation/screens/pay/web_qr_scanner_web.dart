import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Embeds a live camera preview via [HtmlElementView] (works on iOS Safari PWA).
class WebQrScanner extends StatefulWidget {
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
  State<WebQrScanner> createState() => _WebQrScannerState();
}

class _WebQrCameraHost {
  static const viewType = 'zep-pay-camera';
  static var registered = false;
  static html.VideoElement? video;
  static html.MediaStream? stream;

  static void ensureRegistered() {
    if (registered) return;
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final shell = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'hidden'
        ..style.backgroundColor = '#000';
      video = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.display = 'block'
        ..style.backgroundColor = '#000'
        ..setAttribute('playsinline', '')
        ..setAttribute('webkit-playsinline', '')
        ..setAttribute('autoplay', '')
        ..setAttribute('muted', '');
      shell.append(video!);
      return shell;
    });
    registered = true;
  }

  static Future<bool> start() async {
    ensureRegistered();
    final media = html.window.navigator.mediaDevices;
    if (media == null) return false;
    final video = _WebQrCameraHost.video;
    if (video == null) return false;
    try {
      html.MediaStream stream;
      try {
        stream = await media.getUserMedia({
          'audio': false,
          'video': {
            'facingMode': {'ideal': 'environment'},
          },
        });
      } catch (_) {
        stream = await media.getUserMedia({'audio': false, 'video': true});
      }
      _WebQrCameraHost.stream = stream;
      video.srcObject = stream;
      await video.play();
      return true;
    } catch (_) {
      stop();
      return false;
    }
  }

  static void stop() {
    for (final track in stream?.getTracks() ?? <html.MediaStreamTrack>[]) {
      track.stop();
    }
    stream = null;
    video?.srcObject = null;
  }

  static String? decodeFrame() {
    final video = _WebQrCameraHost.video;
    if (video == null) return null;
    final w = video.videoWidth;
    final h = video.videoHeight;
    if (w < 2 || h < 2) return null;
    final canvas = html.CanvasElement(width: w, height: h);
    canvas.context2D.drawImage(video, 0, 0);
    final imageData = canvas.context2D.getImageData(0, 0, w, h);
    final result = js.context.callMethod('zepDecodeQr', [imageData]);
    if (result == null) return null;
    final data = (result as js.JsObject)['data'] as String?;
    if (data == null || data.isEmpty) return null;
    return data;
  }
}

class _WebQrScannerState extends State<WebQrScanner> {
  Timer? _decodeTimer;
  var _live = false;
  var _busy = false;
  var _locked = false;
  String? _error;

  Future<void> _start() async {
    if (_busy || _live) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    _WebQrCameraHost.ensureRegistered();
    setState(() => _live = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final ok = await _WebQrCameraHost.start();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _live = false;
        _busy = false;
        _error = 'blocked';
      });
      widget.onCameraError?.call();
      return;
    }
    widget.onCameraStarted?.call();
    _decodeTimer = Timer.periodic(
      const Duration(milliseconds: 260),
      (_) => _tick(),
    );
    setState(() => _busy = false);
  }

  void _tick() {
    if (_locked || !_live) return;
    final data = _WebQrCameraHost.decodeFrame();
    if (data == null) return;
    _locked = true;
    _decodeTimer?.cancel();
    _stop();
    widget.onDetect(data);
  }

  void _stop() {
    _decodeTimer?.cancel();
    _decodeTimer = null;
    _WebQrCameraHost.stop();
    if (_live) {
      _live = false;
      widget.onCameraStopped?.call();
    }
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_live)
            const HtmlElementView(viewType: _WebQrCameraHost.viewType),
          if (!_live)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 52,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _error == null
                          ? 'Tap to open camera'
                          : 'Camera blocked.\nSafari → Settings → Camera → Allow',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _busy ? null : _start,
                      child: Text(_busy ? 'Starting…' : 'START CAMERA'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
