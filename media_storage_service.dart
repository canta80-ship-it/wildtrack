import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class MediaStorageService {
  static final instance = MediaStorageService();

  Future<Directory> get mediaDirectory async {
    final dir = Directory(p.join(await getDatabasesPath(), 'wildtrack_media'));
    await dir.create(recursive: true);
    return dir;
  }

  Future<String?> persistPhoto(String? sourcePath, String id) async {
    if (sourcePath == null || sourcePath.isEmpty) return null;
    final source = File(sourcePath);
    if (!await source.exists()) return null;
    final extension = p.extension(source.path).toLowerCase();
    final safeExtension = const {'.jpg', '.jpeg', '.png', '.webp'}.contains(extension) ? extension : '.jpg';
    final dir = await mediaDirectory;
    final target = File(p.join(dir.path, '$id$safeExtension'));
    if (p.normalize(source.path) == p.normalize(target.path)) return target.path;
    await source.copy(target.path);
    return target.path;
  }
}
