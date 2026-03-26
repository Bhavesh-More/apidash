import 'package:apidash_storage/apidash_storage.dart';
import 'package:better_networking/better_networking.dart';

Future<void> main() async {
  final workspacePath = '/tmp/apidash-his-poc';
  final workspaceService = WorkspaceService();
  await workspaceService.createWorkspace(workspacePath);

  final collectionService = CollectionService(workspacePath: workspacePath);
  await collectionService.createCollection(
    collectionId: 'col_001',
    name: 'POC Collection',
  );

  final requestService = RequestService(workspacePath: workspacePath);
  await requestService.saveRequest(
    collectionId: 'col_001',
    requestId: 'req_001',
    request: const HttpRequestModel(
      method: HTTPVerb.get,
      url: 'https://example.com',
    ),
    requestName: 'Get Example',
  );

  final request = await requestService.readRequest(
    collectionId: 'col_001',
    requestId: 'req_001',
  );

  print('Loaded request: ${request.method.name.toUpperCase()} ${request.url}');
}
