import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

import 'package:image_picker/image_picker.dart';

/// Decode a QR from a gallery photo with jsQR (same path as live web scan).
Future<String?> decodeQrFromGallery(XFile file) async {
  final bytes = await file.readAsBytes();
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  try {
    final img = html.ImageElement();
    final done = Completer<void>();
    img.onLoad.first.then((_) => done.complete());
    img.onError.first.then((_) => done.completeError(StateError('load')));
    img.src = url;
    await done.future.timeout(const Duration(seconds: 12));
    final w = img.naturalWidth;
    final h = img.naturalHeight;
    if (w < 2 || h < 2) return null;
    final canvas = html.CanvasElement(width: w, height: h);
    canvas.context2D.drawImage(img, 0, 0);
    final imageData = canvas.context2D.getImageData(0, 0, w, h);
    final result = js.context.callMethod('zepDecodeQr', [imageData]);
    if (result == null) return null;
    final data = result['data'] as String?;
    if (data == null || data.isEmpty) return null;
    return data;
  } catch (_) {
    return null;
  } finally {
    html.Url.revokeObjectUrl(url);
  }
}
