import 'dart:convert';

import 'package:image_picker/image_picker.dart';

class ProfileMedia {
  static Future<String?> pick({ImageSource source = ImageSource.gallery}) async {
    final shot = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 88,
    );
    if (shot == null) return null;
    final bytes = await shot.readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }
}
