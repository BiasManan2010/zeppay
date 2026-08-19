import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

import 'package:flutter/material.dart';

/// Live camera is an HTML overlay *on top of* Flutter.
/// [HtmlElementView] and in-canvas video stay grey on iOS Safari PWAs.
class WebQrScanner extends StatefulWidget {
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
  State<WebQrScanner> createState() => _WebQrScannerState();
}

class _WebQrScannerState extends State<WebQrScanner> {
  static const _hostId = 'zep-cam-host';

  html.VideoElement? _video;
  html.DivElement? _host;
  html.MediaStream? _stream;
  Timer? _timer;
  StreamSubscription<html.Event>? _resize;
  var _locked = false;
  var _started = false;
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resize = html.window.onResize.listen((_) => _placeHost());
  }

  Future<void> _start() async {
    if (_busy || _started) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final media = html.window.navigator.mediaDevices;
      if (media == null) {
        throw Exception('no media');
      }
      html.MediaStream stream;
      try {
        stream = await media.getUserMedia({
          'audio': false,
          'video': {
            'facingMode': {'ideal': 'environment'},
          },
        });
      } catch (_) {
        stream = await media.getUserMedia({
          'audio': false,
          'video': true,
        });
      }
      _stream = stream;
      _insertHost();
      final video = _video!;
      video.srcObject = stream;
      await video.play();
      _started = true;
      _timer = Timer.periodic(const Duration(milliseconds: 280), (_) => _tick());
      WidgetsBinding.instance.addPostFrameCallback((_) => _placeHost());
      if (mounted) setState(() => _busy = false);
    } catch (_) {
      _removeHost();
      widget.onCameraError?.call();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'blocked';
      });
    }
  }

  void _insertHost() {
    _removeHost();
    final host = html.DivElement()..id = _hostId;
    final video = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', 'true')
      ..setAttribute('webkit-playsinline', 'true')
      ..setAttribute('autoplay', 'true')
      ..setAttribute('muted', 'true');
    host.append(video);
    html.document.body?.append(host);
    html.document.body?.classes.add('zep-scanning');
    _host = host;
    _video = video;
    _placeHost();
  }

  void _placeHost() {
    final host = _host;
    if (host == null) return;
    final ctx = widget.scanWindowKey?.currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.size.width > 8) {
      final origin = box.localToGlobal(Offset.zero);
      host.style
        ..left = '${origin.dx}px'
        ..top = '${origin.dy}px'
        ..width = '${box.size.width}px'
        ..height = '${box.size.height}px'
        ..transform = 'none';
      host.style.setProperty('-webkit-transform', 'none');
      return;
    }
    host.style
      ..left = '50%'
      ..top = '22%'
      ..width = 'min(72vw, 280px)'
      ..height = 'min(72vw, 280px)';
    host.style.setProperty('transform', 'translateX(-50%) translateZ(0)');
    host.style.setProperty(
      '-webkit-transform',
      'translateX(-50%) translateZ(0)',
    );
  }

  void _tick() {
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
    _removeHost();
    widget.onDetect(data);
  }

  void _removeHost() {
    _timer?.cancel();
    _timer = null;
    for (final track in _stream?.getTracks() ?? <html.MediaStreamTrack>[]) {
      track.stop();
    }
    _stream = null;
    _video?.srcObject = null;
    _host?.remove();
    html.document.getElementById(_hostId)?.remove();
    _host = null;
    _video = null;
    html.document.body?.classes.remove('zep-scanning');
  }

  @override
  void dispose() {
    _resize?.cancel();
    _removeHost();
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
