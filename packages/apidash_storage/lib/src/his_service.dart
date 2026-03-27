import 'dart:io';

import 'package:better_networking/better_networking.dart';
import 'package:path/path.dart' as path;

import 'services/collection_service.dart';
import 'services/request_service.dart';
import 'services/workspace_service.dart';

class HisService {
  HisService({required this.workspacePath})
      : _workspaceService = WorkspaceService(),
        _collectionService = CollectionService(workspacePath: workspacePath),
        _requestService = RequestService(workspacePath: workspacePath);

  final String workspacePath;
  final WorkspaceService _workspaceService;
  final CollectionService _collectionService;
  final RequestService _requestService;

  Future<void> createWorkspace() async {
    await _workspaceService.createWorkspace(workspacePath);
  }

  Future<void> ensureCollection({
    required String collectionId,
    String? collectionName,
  }) async {
    final collectionDir = Directory(
      path.join(workspacePath, 'collections', collectionId),
    );
    if (!await collectionDir.exists()) {
      await _collectionService.createCollection(
        collectionId: collectionId,
        name: collectionName ?? collectionId,
      );
    }
  }

  Future<void> saveRequest({
    required String collectionId,
    required String requestId,
    required HttpRequestModel request,
    String? requestName,
  }) async {
    await ensureCollection(collectionId: collectionId);
    await _requestService.saveRequest(
      collectionId: collectionId,
      requestId: requestId,
      request: request,
      requestName: requestName,
    );
  }

  Future<HttpRequestModel> readRequest({
    required String collectionId,
    required String requestId,
  }) {
    return _requestService.readRequest(
      collectionId: collectionId,
      requestId: requestId,
    );
  }
}
