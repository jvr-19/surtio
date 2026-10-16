import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SavedStationData {
  const SavedStationData(this.payload, this.queriedAt);
  final Map<String, dynamic> payload;
  final DateTime queriedAt;
}

abstract interface class StationCache {
  Future<SavedStationData?> read();
  Future<void> write(SavedStationData data);
}

class FileStationCache implements StationCache {
  const FileStationCache({this.directoryPath});
  final String? directoryPath;
  Future<File> _file() async {
    final directory = directoryPath == null
        ? await getApplicationSupportDirectory()
        : Directory(directoryPath!);
    await directory.create(recursive: true);
    return File('${directory.path}/official-stations-v1.json');
  }

  @override
  Future<SavedStationData?> read() async {
    try {
      final file = await _file();
      if (!await file.exists() || await file.length() > 20000000) return null;
      final saved = jsonDecode(await file.readAsString());
      if (saved is! Map<String, dynamic> ||
          saved['payload'] is! Map<String, dynamic> ||
          saved['queriedAt'] is! String) {
        return null;
      }
      final time = DateTime.tryParse(saved['queriedAt']);
      if (time == null) return null;
      return SavedStationData(saved['payload'] as Map<String, dynamic>, time);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(SavedStationData data) async {
    final file = await _file();
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      jsonEncode({
        'queriedAt': data.queriedAt.toUtc().toIso8601String(),
        'payload': data.payload,
      }),
      flush: true,
    );
    await temporary.rename(file.path);
  }
}
