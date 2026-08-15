import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProfileMedia {
  static Future<String?> pick({ImageSource source = ImageSource.gallery}) async {
    final shot = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 88,
    );
    if (shot == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final dest = File(
      '${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await File(shot.path).copy(dest.path);
    return dest.path;
  }
}
