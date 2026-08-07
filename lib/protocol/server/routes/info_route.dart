import 'dart:convert';

import 'package:sharely/protocol/models/device_info.dart';
import 'package:shelf/shelf.dart';

/// `GET /api/localsend/v2/info` (§6.6).
///
/// Legacy/debug route replaced by `/register` for discovery, but implemented
/// for interop. Returns this device's info block (without the `announce` flag).
Response handleInfo(DeviceInfo deviceInfo) {
  return Response.ok(
    jsonEncode(deviceInfo.toJson()),
    headers: const {'Content-Type': 'application/json'},
  );
}
