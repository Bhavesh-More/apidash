import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'base_command.dart';

class ListCommand extends BaseCommand {
  ListCommand() {
    argParser
      ..addOption(
        'folder',
        abbr: 'f',
        help: 'Folder ID to list requests from',
      )
      ..addOption(
        'request',
        abbr: 'r',
        help: 'Request ID to display full request details',
      );
  }

  @override
  String get name => 'list';

  @override
  String get description =>
      'List collections, folders, or requests from your workspace';

  @override
  Future<void> execute() async {
    final workspacePath = _getWorkspacePath();

    if (workspacePath == null) {
      log.err('APIDASH_WORKSPACE_PATH is not set');
      return;
    }

    final collectionID = argResults?.rest.isNotEmpty == true
        ? argResults!.rest.first
        : null;
    final folderID = argResults?['folder'] as String?;
    final requestID = argResults?['request'] as String?;

    try {
      if (collectionID == null) {
        await _listCollections(workspacePath);
      } else if (requestID != null) {
        await _listRequestDetails(
          workspacePath,
          collectionID,
          folderID,
          requestID,
        );
      } else if (folderID == null) {
        await _listFromCollection(workspacePath, collectionID);
      } else {
        await _listFromFolder(workspacePath, collectionID, folderID);
      }
    } catch (e) {
      log.err('Error: $e');
    }
  }

  Future<void> _listCollections(String workspacePath) async {
    final collectionsDir = Directory(path.join(workspacePath, 'collections'));

    if (!await collectionsDir.exists()) {
      log.info(const JsonEncoder.withIndent('  ').convert({'collections': []}));
      return;
    }

    final entities = await collectionsDir.list(followLinks: false).toList();
    final collectionDirs = entities.whereType<Directory>().toList()
      ..sort((a, b) => path.basename(a.path).compareTo(path.basename(b.path)));

    if (collectionDirs.isEmpty) {
      log.info(const JsonEncoder.withIndent('  ').convert({'collections': []}));
      return;
    }

    final collectionsJson = <Map<String, dynamic>>[];

    for (final collectionDir in collectionDirs) {
      final id = path.basename(collectionDir.path);
      final collectionFile =
          File(path.join(collectionDir.path, 'collection.json'));

      String name = id;
      String activeEnv = 'global';

      if (await collectionFile.exists()) {
        try {
          final raw = await collectionFile.readAsString();
          final decodedJson = jsonDecode(raw);
          if (decodedJson is Map<String, dynamic>) {
            final parsedName = decodedJson['name'];
            if (parsedName is String && parsedName.trim().isNotEmpty) {
              name = parsedName.trim();
            }
            final activeEnvVal = decodedJson['active_env'];
            if (activeEnvVal is String && activeEnvVal.trim().isNotEmpty) {
              activeEnv = activeEnvVal.trim();
            }
          }
        } catch (_) {}
      }

      final requests = await _getRequestsFromIndex(
        workspacePath,
        collectionID: id,
        folderID: null,
      );

      final folderDirs = await _getFoldersInCollection(collectionDir.path);

      collectionsJson.add({
        'id': id,
        'name': name,
        'active_env': activeEnv,
        'requests': requests,
        'folders': folderDirs.map((f) {
          final contents = f['contents'] as Map<String, dynamic>;
          return {
            'id': f['id'],
            'name': f['name'],
            'request_count':
                (contents['requests'] as List?)?.length ?? 0,
          };
        }).toList(),
      });
    }

    log.info(
      const JsonEncoder.withIndent('  ').convert({'collections': collectionsJson}),
    );
  }

  Future<void> _listFromCollection(
    String workspacePath,
    String collectionID,
  ) async {
    final collectionDir = Directory(path.join(
      workspacePath,
      'collections',
      collectionID,
    ));

    if (!await collectionDir.exists()) {
      log.err('Collection "$collectionID" not found');
      return;
    }

    String collectionName = collectionID;
    String activeEnv = 'global';
    final collectionFile =
        File(path.join(collectionDir.path, 'collection.json'));

    if (await collectionFile.exists()) {
      try {
        final raw = await collectionFile.readAsString();
        final decodedJson = jsonDecode(raw);
        if (decodedJson is Map<String, dynamic>) {
          final parsedName = decodedJson['name'];
          if (parsedName is String && parsedName.trim().isNotEmpty) {
            collectionName = parsedName.trim();
          }
          final activeEnvVal = decodedJson['active_env'];
          if (activeEnvVal is String && activeEnvVal.trim().isNotEmpty) {
            activeEnv = activeEnvVal.trim();
          }
        }
      } catch (_) {}
    }

    final requestsInCollection = await _getRequestsFromIndex(
      workspacePath,
      collectionID: collectionID,
      folderID: null,
    );

    final folderDirs = await _getFoldersInCollection(collectionDir.path);

    final output = {
      'collection': {
        'id': collectionID,
        'name': collectionName,
        'active_env': activeEnv,
      },
      'requests': requestsInCollection,
      'folders': folderDirs.map((folder) {
        final contents = folder['contents'] as Map<String, dynamic>;
        return {
          'id': folder['id'],
          'name': folder['name'],
          'request_count': (contents['requests'] as List?)?.length ?? 0,
        };
      }).toList(),
    };

    log.info(const JsonEncoder.withIndent('  ').convert(output));
  }

  Future<void> _listFromFolder(
    String workspacePath,
    String collectionID,
    String folderID,
  ) async {
    final folderDir = Directory(path.join(
      workspacePath,
      'collections',
      collectionID,
      folderID,
    ));

    if (!await folderDir.exists()) {
      log.err('Folder "$folderID" in collection "$collectionID" not found');
      return;
    }

    String folderName = folderID;
    String activeEnv = 'global';
    final folderFile = File(path.join(folderDir.path, 'folder.json'));

    if (await folderFile.exists()) {
      try {
        final raw = await folderFile.readAsString();
        final decodedJson = jsonDecode(raw);
        if (decodedJson is Map<String, dynamic>) {
          final parsedName = decodedJson['name'];
          if (parsedName is String && parsedName.trim().isNotEmpty) {
            folderName = parsedName.trim();
          }
          final activeEnvVal = decodedJson['active_env'];
          if (activeEnvVal is String && activeEnvVal.trim().isNotEmpty) {
            activeEnv = activeEnvVal.trim();
          }
        }
      } catch (_) {}
    }

    final requests = await _getRequestsFromIndex(
      workspacePath,
      collectionID: collectionID,
      folderID: folderID,
    );

    final output = {
      'folder': {
        'id': folderID,
        'name': folderName,
        'active_env': activeEnv,
      },
      'requests': requests,
    };

    log.info(const JsonEncoder.withIndent('  ').convert(output));
  }

  Future<List<Map<String, dynamic>>> _getRequestsFromIndex(
    String workspacePath, {
    required String collectionID,
    String? folderID,
  }) async {
    String indexPath;

    if (folderID != null && folderID.trim().isNotEmpty) {
      indexPath = path.join(
        workspacePath,
        'collections',
        collectionID,
        folderID,
        'folder.json',
      );
    } else {
      indexPath = path.join(
        workspacePath,
        'collections',
        collectionID,
        'collection.json',
      );
    }

    final indexFile = File(indexPath);

    if (!await indexFile.exists()) {
      return [];
    }

    final requests = <Map<String, dynamic>>[];

    try {
      final raw = await indexFile.readAsString();
      final decodedJson = jsonDecode(raw);

      if (decodedJson is Map<String, dynamic>) {
        final requestsList = decodedJson['requests'];

        if (requestsList is List) {
          for (final request in requestsList) {
            if (request is Map<String, dynamic>) {
              final id = request['id'];
              final name = request['name'];
              final method = request['method'];
              final url = request['url'];

              if (id is String &&
                  name is String &&
                  method is String &&
                  url is String) {
                requests.add({
                  'id': id.trim(),
                  'name': name.trim(),
                  'method': method.trim(),
                  'url': url.trim(),
                });
              }
            }
          }
        }
      }
    } catch (_) {}

    return requests;
  }

  Future<List<Map<String, dynamic>>> _getFoldersInCollection(
    String collectionPath,
  ) async {
    final entities =
        await Directory(collectionPath).list(followLinks: false).toList();
    final folderDirs = entities.whereType<Directory>().toList()
      ..sort((a, b) => path.basename(a.path).compareTo(path.basename(b.path)));

    final folders = <Map<String, dynamic>>[];

    for (final folderDir in folderDirs) {
      final id = path.basename(folderDir.path);
      final folderFile = File(path.join(folderDir.path, 'folder.json'));
      String folderName = id;
      Map<String, dynamic> contents = {};

      if (await folderFile.exists()) {
        try {
          final raw = await folderFile.readAsString();
          final decodedJson = jsonDecode(raw);
          if (decodedJson is Map<String, dynamic>) {
            final parsedName = decodedJson['name'];
            if (parsedName is String && parsedName.trim().isNotEmpty) {
              folderName = parsedName.trim();
            }
            contents = decodedJson;
          }
        } catch (_) {}
      }

      folders.add({
        'id': id,
        'name': folderName,
        'contents': contents,
      });
    }

    return folders;
  }

  Future<void> _listRequestDetails(
    String workspacePath,
    String collectionID,
    String? folderID,
    String requestID,
  ) async {
    String requestPath;

    if (folderID != null && folderID.trim().isNotEmpty) {
      requestPath = path.join(
        workspacePath,
        'collections',
        collectionID,
        folderID,
        '$requestID.json',
      );
    } else {
      requestPath = path.join(
        workspacePath,
        'collections',
        collectionID,
        '$requestID.json',
      );
    }

    final requestFile = File(requestPath);

    if (!await requestFile.exists()) {
      log.err('Request "$requestID" not found');
      return;
    }

    try {
      final raw = await requestFile.readAsString();
      final decodedJson = jsonDecode(raw);

      if (decodedJson is Map<String, dynamic>) {
        final name = decodedJson['name'] ?? 'Unknown';
        final method = decodedJson['method'] ?? 'GET';
        final url = decodedJson['url'] ?? '';
        final headers = decodedJson['headers'] as List? ?? [];
        final queryParams = decodedJson['params'] as List? ?? [];
        final auth = decodedJson['auth'] ?? {};
        final body = decodedJson['body'] ?? '';
        final formData = decodedJson['formData'] as List? ?? [];

        // Environment chain
        final folderEnv = await _getActiveEnvAtLevel(
          workspacePath,
          collectionID,
          folderID,
        );
        final collectionEnv =
            await _getActiveEnvAtLevel(workspacePath, collectionID);
        final globalEnv = await _getActiveEnvAtLevel(workspacePath);

        final envChain = <Map<String, String?>>[];
        if (folderID != null && folderID.isNotEmpty && folderEnv != null) {
          envChain.add({'level': 'folder', 'env': folderEnv});
        }
        if (collectionEnv != null) {
          envChain.add({'level': 'collection', 'env': collectionEnv});
        }
        envChain.add({'level': 'global', 'env': globalEnv ?? 'global'});

        final output = {
          'request': {
            'id': requestID,
            'name': name,
            'method': method,
            'url': url,
            'headers': headers.whereType<Map<String, dynamic>>().map((h) => {
                  'key': h['key'] ?? '',
                  'value': h['value'] ?? '',
                  'enabled': h['enabled'] ?? true,
                }).toList(),
            'query_params':
                queryParams.whereType<Map<String, dynamic>>().map((p) => {
                      'key': p['key'] ?? '',
                      'value': p['value'] ?? '',
                      'enabled': p['enabled'] ?? true,
                    }).toList(),
            'auth': auth is Map && auth.isNotEmpty
                ? {'type': auth['type'] ?? 'none'}
                : {'type': 'none'},
            'body': body.toString().isNotEmpty ? body : null,
            'form_data':
                formData.whereType<Map<String, dynamic>>().map((f) => {
                      'key': f['key'] ?? '',
                      'value': f['value'] ?? '',
                    }).toList(),
            'environment_chain': envChain,
          },
        };

        log.info(const JsonEncoder.withIndent('  ').convert(output));
      }
    } catch (e) {
      log.err('Failed to read request: $e');
    }
  }

  Future<String?> _getActiveEnvAtLevel(
    String workspacePath, [
    String? collectionID,
    String? folderID,
  ]) async {
    String indexPath;

    if (folderID != null &&
        folderID.trim().isNotEmpty &&
        collectionID != null) {
      indexPath = path.join(
        workspacePath,
        'collections',
        collectionID,
        folderID,
        'folder.json',
      );
    } else if (collectionID != null && collectionID.trim().isNotEmpty) {
      indexPath = path.join(
        workspacePath,
        'collections',
        collectionID,
        'collection.json',
      );
    } else {
      indexPath = path.join(workspacePath, '.apidash', 'workspace.json');
    }

    final indexFile = File(indexPath);
    if (!await indexFile.exists()) {
      return null;
    }

    try {
      final raw = await indexFile.readAsString();
      final decodedJson = jsonDecode(raw);
      if (decodedJson is Map<String, dynamic>) {
        final activeEnv = decodedJson['active_env'];
        if (activeEnv is String && activeEnv.trim().isNotEmpty) {
          return activeEnv.trim();
        }
      }
    } catch (_) {}

    return null;
  }

  String? _getWorkspacePath() {
    return Platform.environment['APIDASH_WORKSPACE_PATH'];
  }
}