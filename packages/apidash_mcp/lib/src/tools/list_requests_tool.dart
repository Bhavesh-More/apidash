import 'dart:convert';
import 'dart:io';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:path/path.dart' as path;

class RequestSummary {
  final String id;
  final String name;
  final String method;
  final String url;

  const RequestSummary({
    required this.id,
    required this.name,
    required this.method,
    required this.url,
  });

  Map<String, String> toJson() => {
        'id': id,
        'name': name,
        'method': method,
        'url': url,
      };
}

Future<List<RequestSummary>> listRequestsFromCollection(
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
    return const <RequestSummary>[];
  }

  final output = <RequestSummary>[];

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
              output.add(
                RequestSummary(
                  id: id.trim(),
                  name: name.trim(),
                  method: method.trim(),
                  url: url.trim(),
                ),
              );
            }
          }
        }
      }
    }
  } catch (_) {}

  return output;
}

void registerListRequestsTool(
  McpServer server, {
  required String workspacePath,
}) {
  server.registerTool(
    'list_requests',
    description:
        'List all requests from a collection or folder in the API Dash HIS workspace',
    inputSchema: ToolInputSchema(
      properties: {
        'collectionID': JsonSchema.fromJson({
          'type': 'string',
          'description': 'The ID of the collection to list requests from',
        }),
        'folderID': JsonSchema.fromJson({
          'type': 'string',
          'description': 'Optional. The ID of the folder to list requests from',
        }),
      },
      required: ['collectionID'],
    ),
    callback: (args, extra) async {
      final collectionID = args['collectionID'] as String;
      final folderID = args['folderID'] as String?;

      if (collectionID.trim().isEmpty) {
        return CallToolResult.fromContent([
          TextContent(text: jsonEncode([])),
        ]);
      }

      final requests = await listRequestsFromCollection(
        workspacePath,
        collectionID: collectionID,
        folderID: folderID,
      );
      final payload =
          requests.map((request) => request.toJson()).toList();

      return CallToolResult.fromContent([
        TextContent(text: jsonEncode(payload)),
      ]);
    },
  );
}
