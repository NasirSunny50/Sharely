import 'package:sharely/protocol/server/download_session_manager.dart';
import 'package:shelf/shelf.dart';

/// `GET /api/localsend/v2/download?sessionId=&fileId=` (§6.5). Streams binary
/// data, callable in parallel. Sets `Content-Disposition` and `Content-Length`.
Response handleDownload(Request request, DownloadSessionManager manager) {
  final q = request.url.queryParameters;
  final file = manager.resolveDownload(
    sessionId: q['sessionId'],
    fileId: q['fileId'],
  );
  if (file == null) {
    return Response.notFound('Unknown session or file');
  }

  final name = Uri.encodeComponent(file.dto.fileName);
  return Response.ok(
    file.openRead(),
    headers: {
      'Content-Type': file.dto.fileType,
      'Content-Length': '${file.dto.size}',
      'Content-Disposition': "attachment; filename*=UTF-8''$name",
    },
  );
}
