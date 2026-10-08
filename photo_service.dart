import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'database_service.dart';
import 'community_service.dart';
import 'preferences_service.dart';
import 'storage_service.dart';

class PhotoService {
  static Directory get directory => Directory(
    '${PreferencesService.instance.file.parent.path}/sighting_photos',
  );
  static File get recovery => File(
    '${PreferencesService.instance.file.parent.path}/wildtrack_recovered_photo.json',
  );
  static Future<XFile?> pick(
    ImageSource source, {
    required String owner,
    double maxWidth = 1600,
    int quality = 85,
  }) async {
    await JsonStorage.write(recovery, {'owner': owner});
    final result = await ImagePicker().pickImage(
      source: source,
      maxWidth: maxWidth,
      imageQuality: quality,
    );
    if (result != null)
      await JsonStorage.write(recovery, {'owner': owner, 'path': result.path});
    return result;
  }

  static Future<void> recoverLost() async {
    final lost = await ImagePicker().retrieveLostData();
    if (lost.files?.isNotEmpty == true) {
      final data = await JsonStorage.read(recovery, empty: <String, dynamic>{});
      final owner = data is Map ? data['owner'] : 'editor';
      await JsonStorage.write(recovery, {
        'owner': owner ?? 'editor',
        'path': lost.files!.first.path,
      });
    }
  }

  static Future<String?> restored(String owner) async {
    final value = await JsonStorage.read(recovery, empty: <String, dynamic>{});
    if (value is Map && value['owner'] == owner && value['path'] is String) {
      final name = value['path'] as String;
      if (await File(name).exists()) return name;
    }
    return null;
  }

  static Future<void> consumed(String? name) async {
    try {
      final value = await JsonStorage.read(
        recovery,
        empty: <String, dynamic>{},
      );
      if (value is Map && value['path'] == name)
        await JsonStorage.write(recovery, <String, dynamic>{});
    } catch (_) {
      /* A committed observation remains a successful save. */
    }
  }

  static Future<void> deleteIfUnreferenced(String? name) async {
    if (name == null || !path.isWithin(directory.path, name)) return;
    try {
      final db = await DatabaseService.instance.database;
      final rows = await db.query(
        'sightings',
        columns: ['id'],
        where: 'photo_path=?',
        whereArgs: [name],
        limit: 1,
      );
      if (rows.isNotEmpty ||
          CommunityService.instance.pending.any(
            (r) =>
                r['_localSnapshot'] is Map &&
                r['_localSnapshot']['photo_path'] == name,
          ))
        return;
      final recovered = await restored('editor');
      if (recovered == name) return;
      final file = File(name);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Cleanup must not turn an already committed user save into a failure.
    }
  }

  static Future<void> sweep() async {
    if (!await directory.exists()) return;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is File &&
          DateTime.now().difference((await entity.stat()).modified).inDays >=
              1) {
        await deleteIfUnreferenced(entity.path);
      }
    }
  }
}
