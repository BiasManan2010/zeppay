import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

import 'package:flutter/material.dart';

/// Full-screen HTML video *under* Flutter — small fixed overlays stay grey on iOS PWAs.
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
  static const _hostId = 'zep-cam-host';

  html.VideoElement? _video;
  html.DivElement? _host;
  html.MediaStream? _stream;
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
    _resize = html.window.onResize.listen((_) => _syncHost());
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
      await _waitForFrames(video);
      _started = true;
      widget.onCameraStarted?.call();
      html.document.body?.classes.add('zep-scanning');
      _syncHost();
      _timer = Timer.periodic(const Duration(milliseconds: 280), (_) => _tick());
      _placeTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
        _syncHost();
      });
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

  Future<void> _waitForFrames(html.VideoElement video) async {
    for (var i = 0; i < 40; i++) {
      if (video.videoWidth > 1 && video.videoHeight > 1) return;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  void _insertHost() {
    _removeHost(keepCallbacks: true);
    final host = html.DivElement()..id = _hostId;
    final video = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', '')
      ..setAttribute('webkit-playsinline', '')
      ..setAttribute('autoplay', '')
      ..setAttribute('muted', '');
    video.style
      ..width = '100%'
      ..height = '100%'
      ..objectFit = 'cover'
      ..backgroundColor = '#000'
      ..display = 'block';
    host.append(video);
    final body = html.document.body;
    if (body != null) {
      body.insertAdjacentElement('afterbegin', host);
    }
    _host = host;
    _video = video;
    _syncHost();
  }

  void _syncHost() {
    final host = _host;
    if (host == null) return;
    host.style
      ..position = 'fixed'
      ..left = '0'
      ..top = '0'
      ..width = '100%'
      ..height = '100%'
      ..zIndex = '0'
      ..overflow = 'hidden'
      ..pointerEvents = 'none'
      ..margin = '0'
      ..padding = '0'
      ..transform = 'none'
      ..backgroundColor = '#000';
    host.style.setProperty('-webkit-transform', 'none');
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
    _placeTimer?.cancel();
    _removeHost();
    widget.onDetect(data);
  }

  void _removeHost({bool keepCallbacks = false}) {
    _timer?.cancel();
    _timer = null;
    _placeTimer?.cancel();
    _placeTimer = null;
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
    if (_started && !keepCallbacks) {
      _started = false;
      widget.onCameraStopped?.call();
    }
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
