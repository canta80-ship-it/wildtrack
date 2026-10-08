import 'dart:convert';
import 'dart:io';

/// A failed transaction never poisons subsequent operations.
class SerialExecutor {
  Future<void> _tail = Future<void>.value();
  Future<T> run<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}

class JsonStorage {
  static int _sequence = 0;
  static Future<Object?> read(File file, {required Object empty}) async {
    if (!await file.exists() && !await File('${file.path}.bak').exists()) {
      return empty;
    }
    Object? lastError;
    for (final candidate in [file, File('${file.path}.bak')]) {
      try {
        return jsonDecode(await candidate.readAsString());
      } catch (e) {
        lastError = e;
      }
    }
    throw FileSystemException(
      'Archivio non leggibile: i file originali sono conservati. $lastError',
      file.path,
    );
  }

  static Future<void> write(File file, Object value) async {
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.${_sequence++}.tmp');
    try {
      await temporary.writeAsString(jsonEncode(value), flush: true);
      if (await file.exists()) {
        // Never replace a valid recovery copy with a corrupt original.
        var valid = false;
        try {
          jsonDecode(await file.readAsString());
          valid = true;
        } on FormatException {
          valid = false;
        }
        if (valid) await file.copy('${file.path}.bak');
      }
      await temporary.rename(file.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }
}
