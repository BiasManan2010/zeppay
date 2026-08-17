import 'dart:convert';

import 'package:flutter/widgets.dart';

ImageProvider? mediaImage(String path) {
  if (path.isEmpty) return null;
  if (path.startsWith('data:')) {
    final b64 = path.substring(path.indexOf(',') + 1);
    return MemoryImage(base64Decode(b64));
  }
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  }
  return null;
}

bool mediaExists(String path) {
  return path.startsWith('data:') ||
      path.startsWith('http://') ||
      path.startsWith('https://');
}
