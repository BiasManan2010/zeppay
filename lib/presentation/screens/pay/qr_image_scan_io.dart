import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Decode a QR from a gallery photo using [MobileScannerController].
Future<String?> decodeQrFromGallery(XFile file) async {
  final ctrl = MobileScannerController();
  try {
    final cap = await ctrl.analyzeImage(file.path);
    if (cap == null || cap.barcodes.isEmpty) return null;
    final b = cap.barcodes.first;
    final raw = b.rawValue?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    final shown = b.displayValue?.trim();
    if (shown != null && shown.isNotEmpty) return shown;
    return null;
  } finally {
    await ctrl.dispose();
  }
}
