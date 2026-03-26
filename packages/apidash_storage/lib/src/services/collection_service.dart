import 'dart:io';
import 'package:path/path.dart' as path;
import 'file_service.dart';
import 'dart:developer' as developer;

class CollectionService {
  CollectionService({required this.workspacePath, FileService? fileService})
      : _fileService = fileService ?? const FileService();

  final String workspacePath;
  final FileService _fileService;

  Future<void> createCollection({
    required String collectionId,
    required String name,
    String activeEnv = 'global',
  }) async {
    final collectionDir = Directory(
      path.join(workspacePath, 'collections', collectionId),
    );

    await _fileService.isDirExists(collectionDir);

    await _fileService.writeJsonFile(
      File(path.join(collectionDir.path, 'collection.json')),
      <String, Object?>{
        'id': collectionId,
        'name': name,
        'active_env': activeEnv,
        'requests': <Object?>[],
      },
    );
  }

  Future<Map<String, Object?>> readCollectionIndex(String collectionId) async {
    final collectionFile = File(
      path.join(workspacePath, 'collections', collectionId, 'collection.json'),
    );

    if (!await collectionFile.exists()) {
      developer.log('Collection index not found: ${collectionFile.path}');
      throw Exception('Collection not found: $collectionId');
    }

    return _fileService.readJsonFile(collectionFile);
  }

  // adds or updates a request entry inside a collection.json
  Future<void> upsertRequestIndexEntry({
    required String collectionId,
    required String requestId,
    required String method,
    required String url,
    required String name,
    required String file,
  }) async {
    final collectionFile = File(
      path.join(workspacePath, 'collections', collectionId, 'collection.json'),
    );

    if (!await collectionFile.exists()) {
      throw Exception('Collection not found: $collectionId');
    }

    final index = await _fileService.readJsonFile(collectionFile);
    final currentRequests = (index['requests'] as List?) ?? <Object?>[];

    final updatedRequests = List<Map<String, Object?>>.from(
      currentRequests
          .whereType<Map>()
          .map((e) => Map<String, Object?>.from(e))
          .where((entry) => entry['id'] != requestId),
    );

    updatedRequests.add(<String, Object?>{
      'id': requestId,
      'name': name,
      'method': method,
      'url': url,
      'file': file,
    });

    index['requests'] = updatedRequests;
    await _fileService.writeJsonFile(collectionFile, index);
  }
}
