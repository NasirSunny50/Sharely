import 'dart:convert';

import 'package:sharely/protocol/models/device_info.dart';
import 'package:shelf/shelf.dart';

/// Callback invoked with a peer's info when it registers. The discovery layer
/// supplies this to record the peer.
typedef RegisterHandler = void Function(DeviceInfo peer);

/// `POST /api/localsend/v2/register` (§6.3.1 preferred reply path, §6.3.2 HTTP
/// legacy discovery).
///
/// A peer POSTs its own device info; we record it (via [onRegister]) and reply
/// with **our** device info. Fingerprint is ignored in HTTPS mode per spec, but
/// we still echo the peer through the handler so the discovery layer can dedupe.
Future<Response> handleRegister(
  Request request,
  DeviceInfo selfInfo,
  RegisterHandler? onRegister,
) async {
  final body = await request.readAsString();
  Map<String, dynamic> json;
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      return _badRequest('Body must be a JSON object');
    }
    json = decoded;
  } on FormatException {
    return _badRequest('Invalid JSON');
  }

  final peer = DeviceInfo.fromJson(json);
  // A register from a peer with no alias/fingerprint is malformed.
  if (peer.alias.isEmpty) {
    return _badRequest('Missing alias');
  }
  onRegister?.call(peer);

  return Response.ok(
    jsonEncode(selfInfo.toJson()),
    headers: const {'Content-Type': 'application/json'},
  );
}

Response _badRequest(String message) => Response(
      400,
      body: jsonEncode({'message': message}),
      headers: const {'Content-Type': 'application/json'},
    );
