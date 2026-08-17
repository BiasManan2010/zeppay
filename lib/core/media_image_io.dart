import 'dart:convert';
import 'dart:io';

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
  final file = File(path);
  if (!file.existsSync()) return null;
  return FileImage(file);
}

bool mediaExists(String path) {
  if (path.isEmpty) return false;
  if (path.startsWith('data:') ||
      path.startsWith('http://') ||
      path.startsWith('https://')) {
    return true;
  }
  return File(path).existsSync();
}
