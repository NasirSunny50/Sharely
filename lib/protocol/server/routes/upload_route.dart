import 'dart:convert';

import 'package:sharely/protocol/server/session_manager.dart';
import 'package:shelf/shelf.dart';

/// `POST /api/localsend/v2/upload?sessionId=&fileId=&token=` (§6.4.2).
///
/// The body is raw binary, streamed straight to disk. May be called in
/// parallel. Errors: 400 missing params, 403 invalid token/IP, 409 blocked by
/// another session, 500 unknown.
Future<Response> handleUpload(
  Request request,
  ReceiveSessionManager manager,
  String remoteIp,
) async {
  final q = request.url.queryParameters;
  try {
    await manager.handleUpload(
      sessionId: q['sessionId'],
      fileId: q['fileId'],
      token: q['token'],
      remoteIp: remoteIp,
      body: request.read(),
    );
    return Response.ok(null);
  } on UploadError catch (e) {
    return Response(
      e.statusCode,
      body: jsonEncode({'message': e.message}),
      headers: const {'Content-Type': 'application/json'},
    );
  }
}
