import 'dart:convert';

import 'package:sharely/protocol/models/prepare_upload_dto.dart';
import 'package:sharely/protocol/server/session_manager.dart';
import 'package:shelf/shelf.dart';

/// `POST /api/localsend/v2/prepare-upload` (§6.4.1). Optional `?pin=`.
///
/// Parses the request, hands the accept/partial/reject decision to the session
/// manager, and maps the outcome to the spec's status codes:
/// 200 accepted · 204 nothing to do · 400 invalid body · 401 PIN ·
/// 403 rejected · 409 blocked · 429 too many · 500 unknown.
Future<Response> handlePrepareUpload(
  Request request,
  ReceiveSessionManager manager,
  String remoteIp,
) async {
  final body = await request.readAsString();
  PrepareUploadRequest parsed;
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      return _json(400, {'message': 'Invalid body'});
    }
    parsed = PrepareUploadRequest.fromJson(decoded);
  } on Object {
    return _json(400, {'message': 'Invalid body'});
  }

  final pin = request.url.queryParameters['pin'];

  final outcome = await manager.prepareUpload(parsed, remoteIp, pin: pin);
  return switch (outcome) {
    PrepareAccepted(:final response) =>
      _json(200, response.toJson()),
    PrepareFinished() => Response(204),
    PrepareFailed(:final statusCode, :final message) =>
      _json(statusCode, {'message': message}),
  };
}

Response _json(int status, Map<String, dynamic> body) => Response(
      status,
      body: jsonEncode(body),
      headers: const {'Content-Type': 'application/json'},
    );
