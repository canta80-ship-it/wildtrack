import 'dart:typed_data';
import 'package:flutter/services.dart';

class PickedWildFile {
  const PickedWildFile(this.name, this.mime, this.bytes);
  final String name, mime;
  final Uint8List bytes;
  static Future<PickedWildFile?> pick() async {
    final row = await const MethodChannel('wildtrack/files').invokeMapMethod<String, dynamic>('pick');
    if (row == null) return null;
    return PickedWildFile(row['name'] as String, row['mime'] as String, row['data'] as Uint8List);
  }
}
