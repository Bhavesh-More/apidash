import 'package:apidash_storage/apidash_storage.dart';
import 'package:better_networking/better_networking.dart';
import 'package:test/test.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

void main() {
  group('apidash_storage POC', () {
    test('creates workspace and saves/reads request', () async {
      final tempRoot = await Directory.systemTemp.createTemp('his_poc_');
      final workspacePath = path.join(tempRoot.path, 'workspace');

      final workspaceService = WorkspaceService();
      await workspaceService.createWorkspace(workspacePath);

      final collectionService = CollectionService(workspacePath: workspacePath);
      await collectionService.createCollection(
        collectionId: 'col_001',
        name: 'POC Collection',
      );

      final requestService = RequestService(workspacePath: workspacePath);
      const request = HttpRequestModel(
        method: HTTPVerb.get,
        url: 'https://example.com/users',
      );

      await requestService.saveRequest(
        collectionId: 'col_001',
        requestId: 'req_001',
        request: request,
        requestName: 'Get Users',
      );

      final loaded = await requestService.readRequest(
        collectionId: 'col_001',
        requestId: 'req_001',
      );

      expect(loaded.method, HTTPVerb.get);
      expect(loaded.url, 'https://example.com/users');

      final index = await collectionService.readCollectionIndex('col_001');
      final requests = index['requests'] as List;
      expect(requests, isNotEmpty);

      await tempRoot.delete(recursive: true);
    });
  });
}
