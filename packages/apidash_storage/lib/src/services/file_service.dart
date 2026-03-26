import 'dart:convert';
import 'dart:io';

class FileService {
  const FileService();

  Future<void> isDirExists(Directory directory) async {
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  Future<void> writeJsonFile(File file, Map<String, Object?> jsonData) async {
    await isDirExists(file.parent);
    final encoder = const JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(jsonData));
  }

  Future<Map<String, Object?>> readJsonFile(File file) async {
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Expected JSON object');
    }
    return Map<String, Object?>.from(decoded);
  }

  bool fileExistsSync(String filePath) {
    return File(filePath).existsSync();
  }

  String? getHomeDirectoryPath() {
    return Platform.environment['HOME'];
  }
}
