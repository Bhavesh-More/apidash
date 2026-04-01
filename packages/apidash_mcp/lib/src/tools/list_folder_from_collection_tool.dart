import 'dart:convert';
import 'dart:io';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:path/path.dart' as path;

class FolderSummary{
  final String folderName;
  final String id;

  const FolderSummary({
    required this.folderName,
    required this.id,
  });

  Map<String, String> toJson() => {
    'folderName' : folderName,
    'id' : id,
  };

}

Future<List<FolderSummary>> listFoldersFromCollection(String workspacePath, { required String collectionID}) async {

  final collectionDir = Directory(path.join(workspacePath, 'collections', collectionID));

  if (!await collectionDir.exists()) {
    return const <FolderSummary>[];
  }

  final entities = await collectionDir.list(followLinks: false).toList();
  final folderDirs = entities.whereType<Directory>().toList()
    ..sort((a, b) => path.basename(a.path).compareTo(path.basename(b.path)));
  
  List<FolderSummary> output = [];

  for (final folderDir in folderDirs) {
    final id = path.basename(folderDir.path);
    final folderFile = File(path.join(folderDir.path, 'folder.json'));
    String folderName = id;

    
    if (await folderFile.exists()) {
      try {
        final raw = await folderFile.readAsString();
        final decodedJson = jsonDecode(raw);
        if (decodedJson is Map<String, dynamic>) {
          final parsedName = decodedJson['name'];
          if (parsedName is String && parsedName.trim().isNotEmpty) {
            folderName = parsedName.trim();
          }
        }
      } catch (_) { }
    }

    output.add(FolderSummary(folderName: folderName, id: id));
  }

  return output;
}

void registerListFoldersFromCollectionTool(  McpServer server, {
  required String workspacePath,
}) {

  server.registerTool('list_folders', 
  description: 'List folders from a collection',
  inputSchema: ToolInputSchema(
    properties: {
      'collectionID': JsonSchema.fromJson({
        'type': 'string',
        'description': 'The ID of the collection to list folders from',
      }),
    },
    required: ['collectionID'],
  ),
  callback: (args, extra) async {
      final collectionID = args['collectionID'] as String;
      if (collectionID.trim().isEmpty) {
        return CallToolResult.fromContent([
          TextContent(text: jsonEncode([])),
        ]);
      }
      final folders = await listFoldersFromCollection(workspacePath, collectionID: collectionID);
      final payload = folders.map((folder) => folder.toJson()).toList();

      return CallToolResult.fromContent([
        TextContent(text: jsonEncode(payload)),
      ]);
    },
  );
 }