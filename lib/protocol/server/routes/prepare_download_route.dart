import 'dart:convert';

import 'package:sharely/protocol/server/download_session_manager.dart';
import 'package:shelf/shelf.dart';

/// `POST /api/localsend/v2/prepare-download` (§6.5). No request body; optional
/// `?sessionId=` (browser refresh reuse) and `?pin=`. Returns `info`,
/// `sessionId`, and the `files` map. Errors: 401, 403, 429, 500.
Future<Response> handlePrepareDownload(
  Request request,
  DownloadSessionManager manager,
) async {
  final q = request.url.queryParameters;
  final result = manager.prepareDownload(
    requestedSessionId: q['sessionId'],
    pin: q['pin'],
  );
  final response = result.response;
  if (response == null) {
    return Response(
      result.status,
      body: jsonEncode({'message': 'prepare-download failed'}),
      headers: const {'Content-Type': 'application/json'},
    );
  }
  return Response.ok(
    jsonEncode(response.toJson()),
    headers: const {'Content-Type': 'application/json'},
  );
}
