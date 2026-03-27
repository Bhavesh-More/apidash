import 'dart:convert';

import 'package:apidash_storage/apidash_storage.dart';
import 'package:better_networking/better_networking.dart';

import 'base_command.dart';

class ExecCommand extends BaseCommand {
  ExecCommand() {
    argParser
      ..addOption('method', abbr: 'm', defaultsTo: 'GET')
      ..addOption('url', abbr: 'u')
      ..addFlag('save', defaultsTo: false)
      ..addOption('collection', defaultsTo: 'col_001')
      ..addOption('request-id')
      ..addOption('name');
  }

  @override
  String get name => 'exec';

  @override
  String get description => 'Execute an HTTP request from terminal';

  @override
  Future<void> execute() async {
    final results = argResults;
    if (results == null) {
      log.err('Unable to read parsed arguments.');
      return;
    }

    final methodRaw = ((results['method'] as String?) ?? 'GET').trim();
    final url = (results['url'] as String?)?.trim();
    final save = (results['save'] as bool?) ?? false;
    final collectionId = (results['collection'] as String?) ?? 'col_001';
    final requestId =
        (results['request-id'] as String?)?.trim().isNotEmpty == true
            ? (results['request-id'] as String).trim()
            : 'req_${DateTime.now().millisecondsSinceEpoch}';

    if (url == null || url.isEmpty) {
      log.err('Missing url. Usage: apidash exec --url=<url> [--method=GET]');
      return;
    }

    HTTPVerb method;
    try {
      method = HTTPVerb.values.byName(methodRaw.toLowerCase());
    } catch (_) {
      log.err('Unsupported method: $methodRaw');
      return;
    }

    final request = HttpRequestModel(method: method, url: url);
    final (response, duration, error) = await sendHttpRequest(
      requestId,
      APIType.rest,
      request,
    );

    if (error != null || response == null) {
      log.err(error ?? 'Request failed');
      return;
    }

    final httpResponseModel = const HttpResponseModel().fromResponse(
      response: response,
      time: duration,
    );

    final output = Map<String, dynamic>.from(httpResponseModel.toJson())
      ..remove('bodyBytes');
    const encoder = JsonEncoder.withIndent('  ');
    log.write(encoder.convert(output));

    if (save) {
      final workspaceService = WorkspaceService();
      final workspacePath = await workspaceService.resolveWorkspacePath();
      if (workspacePath == null || workspacePath.isEmpty) {
        log.warn(
          'APIDASH_WORKSPACE_PATH is not set. Skipping --save. '
          'Run init and export the workspace path first.',
        );
        return;
      }

      final his = HisService(workspacePath: workspacePath);
      await his.saveRequest(
        collectionId: collectionId,
        requestId: requestId,
        request: request,
        requestName: (results['name'] as String?) ?? '$methodRaw $url',
      );
      log.success('Saved request as $requestId in collection $collectionId');
    }
  }
}
