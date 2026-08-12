import 'package:collection/collection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/models.dart';

class OcrService {
  Future<List<LineItem>> itemize(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer();
    try {
      final result = await recognizer.processImage(input);
      return parseLines(result.text);
    } finally {
      await recognizer.close();
    }
  }

  static List<LineItem> parseLines(String text) {
    final items = <LineItem>[];
    final amount = RegExp(r'(?:₹|Rs\.?\s*)?(\d+[.,]\d{2}|\d+)');
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final match = amount.allMatches(trimmed).lastOrNull;
      if (match == null) continue;
      final rupees = double.tryParse(match.group(1)!.replaceAll(',', '')) ?? 0;
      if (rupees <= 0) continue;
      final label = trimmed.replaceAll(match.group(0)!, '').trim();
      if (label.isEmpty) continue;
      items.add(LineItem(label: label, amountPaise: (rupees * 100).round()));
    }
    return items;
  }
}
