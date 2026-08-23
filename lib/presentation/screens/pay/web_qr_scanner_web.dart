import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;

import 'package:flutter/material.dart';

/// iOS Safari PWA: camera must start inside the tap gesture via JS, and the
/// preview must be an HTML overlay on top of the opaque Flutter canvas.
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
  Timer? _decodeTimer;
  Timer? _placeTimer;
  StreamSubscription<html.Event>? _resize;
  var _live = false;
  var _busy = false;
  var _locked = false;
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

  /// Must stay synchronous through the JS getUserMedia call (iOS Safari).
  void _start() {
    if (_busy || _live) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final rect = _scanRect();
    js.context.callMethod('zepStartCamera', [
      rect == null ? null : js.JsObject.jsify(rect),
      js_util.allowInterop((_) {
        if (!mounted) return;
        _live = true;
        widget.onCameraStarted?.call();
        _placeCamera();
        WidgetsBinding.instance.addPostFrameCallback((_) => _placeCamera());
        _decodeTimer = Timer.periodic(
          const Duration(milliseconds: 260),
          (_) => _tick(),
        );
        _placeTimer = Timer.periodic(
          const Duration(milliseconds: 350),
          (_) => _placeCamera(),
        );
        setState(() => _busy = false);
      }),
      js_util.allowInterop((_) {
        js.context.callMethod('zepStopCamera');
        widget.onCameraError?.call();
        if (!mounted) return;
        setState(() {
          _busy = false;
          _live = false;
          _error = 'blocked';
        });
      }),
    ]);
  }

  void _tick() {
    if (_locked || !_live) return;
    final result = js.context.callMethod('zepGrabCameraFrame');
    if (result == null) return;
    final data = (result as js.JsObject)['data'] as String?;
    if (data == null || data.isEmpty) return;
    _locked = true;
    _decodeTimer?.cancel();
    _placeTimer?.cancel();
    _stop();
    widget.onDetect(data);
  }

  void _stop() {
    _decodeTimer?.cancel();
    _decodeTimer = null;
    _placeTimer?.cancel();
    _placeTimer = null;
    js.context.callMethod('zepStopCamera');
    if (_live) {
      _live = false;
      widget.onCameraStopped?.call();
    }
  }

  @override
  void dispose() {
    _resize?.cancel();
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_live) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _error == null
                ? 'Safari needs one tap to open the camera.'
                : 'Camera blocked. Settings → Safari → Camera → Allow, then tap again.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, height: 1.4, fontSize: 14),
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
