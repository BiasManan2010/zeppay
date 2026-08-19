import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;

import 'package:flutter/material.dart';

/// iOS Safari needs the camera started from JS in the same user-gesture turn.
/// The preview is an HTML overlay on top of the opaque Flutter canvas.
class WebQrScanner extends StatefulWidget {
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
  State<WebQrScanner> createState() => _WebQrScannerState();
}

class _WebQrScannerState extends State<WebQrScanner> {
  Timer? _timer;
  Timer? _placeTimer;
  StreamSubscription<html.Event>? _resize;
  var _locked = false;
  var _started = false;
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resize = html.window.onResize.listen((_) => _placeCamera());
  }

  Map<String, double>? _scanRect() {
    final ctx = widget.scanWindowKey?.currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.width < 8) return null;
    final origin = box.localToGlobal(Offset.zero);
    return {
      'left': origin.dx,
      'top': origin.dy,
      'width': box.size.width,
      'height': box.size.height,
    };
  }

  void _placeCamera() {
    final rect = _scanRect();
    if (rect == null) return;
    js.context.callMethod('zepPlaceCamera', [js.JsObject.jsify(rect)]);
  }

  void _start() {
    if (_busy || _started) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final rect = _scanRect();
    js.context.callMethod('zepStartCamera', [
      rect == null ? null : js.JsObject.jsify(rect),
      js_util.allowInterop((_) {
        if (!mounted) return;
        _started = true;
        widget.onCameraStarted?.call();
        _placeCamera();
        WidgetsBinding.instance.addPostFrameCallback((_) => _placeCamera());
        _timer = Timer.periodic(const Duration(milliseconds: 280), (_) => _tick());
        _placeTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
          _placeCamera();
        });
        setState(() => _busy = false);
      }),
      js_util.allowInterop((_) {
        js.context.callMethod('zepStopCamera');
        widget.onCameraError?.call();
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = 'blocked';
        });
      }),
    ]);
  }

  void _tick() {
    if (_locked || !_started) return;
    final result = js.context.callMethod('zepGrabCameraFrame');
    if (result == null) return;
    final data = (result as js.JsObject)['data'] as String?;
    if (data == null || data.isEmpty) return;
    _locked = true;
    _timer?.cancel();
    _placeTimer?.cancel();
    _stopCamera();
    widget.onDetect(data);
  }

  void _stopCamera() {
    _timer?.cancel();
    _timer = null;
    _placeTimer?.cancel();
    _placeTimer = null;
    js.context.callMethod('zepStopCamera');
    if (_started) {
      _started = false;
      widget.onCameraStopped?.call();
    }
  }

  @override
  void dispose() {
    _resize?.cancel();
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_started) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _error == null
                ? 'Safari needs one tap to open the camera.'
                : 'Camera is blocked. Settings → Safari → Camera → Allow, then tap again.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, height: 1.4),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _start,
            child: Text(_busy ? 'Starting…' : 'START CAMERA'),
          ),
        ],
      ),
    );
  }
}
