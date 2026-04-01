import 'dart:io';
import 'package:apidash_storage/src/services/folder_service.dart';
import 'package:better_networking/better_networking.dart';
import 'package:path/path.dart' as path;
import 'collection_service.dart';
import 'file_service.dart';

class RequestService {
  RequestService({
    required this.workspacePath,
    CollectionService? collectionService,
    FileService? fileService,
    FolderServices? folderServices,
  })  : _fileService = fileService ?? const FileService(),
        _collectionService =
            collectionService ?? CollectionService(workspacePath: workspacePath),
        _folderServices = folderServices ?? FolderServices(workspacePath: workspacePath);

  final String workspacePath;
  final FileService _fileService;
  final CollectionService _collectionService;
  final FolderServices _folderServices;

  Future<void> saveRequest({
    required String collectionId,
    required String requestId,
    required HttpRequestModel request,
    String? folderId,
    String? requestName,
  }) async {

    final collectionDir = Directory(
      path.join(workspacePath, 'collections', collectionId),
    );

    if (!await collectionDir.exists()) {
      throw Exception('Collection not found: $collectionId');
    }

    final fileName = '$requestId.json';

     File requestFile;

    if(folderId != null) {
      final folderDir = Directory(
        path.join(workspacePath, 'collections', collectionId, folderId),
      );
      if (!await folderDir.exists()) {
        throw Exception('Folder not found: $folderId in collection $collectionId');
      }
      requestFile = File(path.join(folderDir.path, fileName));
      await _fileService.writeJsonFile(requestFile, request.toJson());
      await _folderServices.upsertRequestIndexEntry(
        collectionId: collectionId,
        folderId: folderId,
        requestId: requestId,
        method: request.method.name.toUpperCase(),
        url: request.url,
        name: requestName ?? '$request.url',
        file: fileName,
      );
    }
    else {

      requestFile = File(path.join(collectionDir.path, fileName));
      await _fileService.writeJsonFile(requestFile, request.toJson());
      await _collectionService.upsertRequestIndexEntry(
        collectionId: collectionId,
        requestId: requestId,
        method: request.method.name.toUpperCase(),
        url: request.url,
        name: requestName ?? '$request.url',
        file: fileName,
      );
    }
    
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