import 'package:sharely/protocol/server/session_manager.dart';
import 'package:shelf/shelf.dart';

/// `POST /api/localsend/v2/cancel?sessionId=` (§6.4.3). No response body.
///
/// Wired to sender-side cancel, app backgrounding, and socket death. The
/// receiver deletes partial files on cancel.
Future<Response> handleCancel(
  Request request,
  ReceiveSessionManager manager,
) async {
  final sessionId = request.url.queryParameters['sessionId'];
  await manager.cancel(sessionId);
  return Response.ok(null);
}
