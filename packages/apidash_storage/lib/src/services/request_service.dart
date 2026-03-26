import 'dart:io';
import 'package:better_networking/better_networking.dart';
import 'package:path/path.dart' as path;
import 'collection_service.dart';
import 'file_service.dart';

class RequestService {
  RequestService({
    required this.workspacePath,
    CollectionService? collectionService,
    FileService? fileService,
  })  : _fileService = fileService ?? const FileService(),
        _collectionService =
            collectionService ?? CollectionService(workspacePath: workspacePath);

  final String workspacePath;
  final FileService _fileService;
  final CollectionService _collectionService;

  Future<void> saveRequest({
    required String collectionId,
    required String requestId,
    required HttpRequestModel request,
    String? requestName,
  }) async {
    final collectionDir = Directory(
      path.join(workspacePath, 'collections', collectionId),
    );

    if (!await collectionDir.exists()) {
      throw Exception('Collection not found: $collectionId');
    }

    final fileName = '$requestId.json';
    final requestFile = File(path.join(collectionDir.path, fileName));

    await _fileService.writeJsonFile(requestFile, request.toJson());

    await _collectionService.upsertRequestIndexEntry(
      collectionId: collectionId,
      requestId: requestId,
      method: request.method.name.toUpperCase(),
      url: request.url,
      name: requestName ?? '${request.method.name.toUpperCase()} ${request.url}',
      file: fileName,
    );
  }

  Future<HttpRequestModel> readRequest({
    required String collectionId,
    required String requestId,
  }) async {
    final requestFile = File(
      path.join(workspacePath, 'collections', collectionId, '$requestId.json'),
    );

    if (!await requestFile.exists()) {
      throw Exception('Request not found: $requestId in $collectionId');
    }

    final json = await _fileService.readJsonFile(requestFile);
    return HttpRequestModel.fromJson(json);
  }
}
