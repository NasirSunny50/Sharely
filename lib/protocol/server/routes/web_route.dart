import 'dart:convert';

import 'package:sharely/core/constants.dart';
import 'package:sharely/protocol/models/file_dto.dart';
import 'package:sharely/protocol/server/download_session_manager.dart';
import 'package:shelf/shelf.dart';

/// `GET /` — the browser-mode landing page the *receiver* sees in Chrome or
/// Safari (§6.5, screen 24). A single self-contained, dependency-free HTML page
/// listing the files with individual and download-all links. Styled in the
/// Sharely palette; works on a phone and a desktop browser.
Response handleWebPage(Request request, DownloadSessionManager manager) {
  final result = manager.prepareDownload();
  final response = result.response;
  if (response == null) {
    return Response(
      result.status,
      body: _errorPage(result.status),
      headers: const {'Content-Type': 'text/html; charset=utf-8'},
    );
  }
  final sessionId = response.sessionId;
  final files = response.files.values.toList();
  return Response.ok(
    _page(sessionId, files),
    headers: const {'Content-Type': 'text/html; charset=utf-8'},
  );
}

String _humanBytes(int value) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  if (value < 1024) return '$value B';
  var size = value.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  return '${size.toStringAsFixed(size >= 100 ? 0 : 1)} ${units[unit]}';
}

String _downloadUrl(String sessionId, String fileId) =>
    '${SharelyConstants.apiBase}/download?sessionId=$sessionId&fileId=$fileId';

String _page(String sessionId, List<FileDto> files) {
  final rows = files.map((f) {
    final name = const HtmlEscape().convert(f.fileName);
    return '''
      <li class="row">
        <div class="meta">
          <span class="name">$name</span>
          <span class="size">${_humanBytes(f.size)}</span>
        </div>
        <a class="dl" href="${_downloadUrl(sessionId, f.id)}" download>Download</a>
      </li>''';
  }).join();

  final totalBytes = files.fold<int>(0, (s, f) => s + f.size);

  return '''
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Sharely</title>
<style>
  :root { color-scheme: light; }
  * { box-sizing: border-box; }
  body {
    margin: 0; background: #DCD6C8; color: #14120F;
    font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
    display: flex; justify-content: center; padding: 24px;
  }
  .card {
    width: 100%; max-width: 560px; background: #F4F1EA;
    border: 1px solid #E4DED1; border-radius: 20px; overflow: hidden;
  }
  header { padding: 24px; border-bottom: 1px solid #E4DED1; }
  .brand { display: flex; align-items: center; gap: 10px; }
  .logo {
    width: 34px; height: 34px; border-radius: 9px; background: #14120F;
    box-shadow: 0 2px 0 #C33C15; display: grid; place-items: center; color: #F4F1EA;
    font-weight: 700;
  }
  h1 { font-size: 19px; margin: 0; font-weight: 700; }
  .sub { color: #6B6459; font-size: 13px; margin-top: 2px; }
  ul { list-style: none; margin: 0; padding: 8px; }
  .row {
    display: flex; align-items: center; gap: 12px; background: #FFFFFF;
    border: 1px solid #E4DED1; border-radius: 14px; padding: 12px 14px; margin: 8px;
  }
  .meta { flex: 1; min-width: 0; display: flex; flex-direction: column; }
  .name { font-weight: 600; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .size { color: #8C8477; font-size: 12px; font-variant-numeric: tabular-nums; }
  a.dl, button.all {
    background: #C33C15; color: #FFF6F2; text-decoration: none; border: none;
    font: inherit; font-weight: 600; padding: 10px 16px; border-radius: 12px;
    box-shadow: 0 3px 0 #8E2A0D; cursor: pointer;
  }
  a.dl:active, button.all:active { transform: translateY(2px); box-shadow: 0 1px 0 #8E2A0D; }
  footer { padding: 16px 24px 24px; }
  button.all { width: 100%; padding: 14px; box-shadow: 0 4px 0 #8E2A0D; }
  .note { color: #8C8477; font-size: 12px; text-align: center; margin-top: 12px; }
</style>
</head>
<body>
  <main class="card">
    <header>
      <div class="brand">
        <span class="logo">S</span>
        <div>
          <h1>Sharely</h1>
          <div class="sub">${files.length} files &middot; ${_humanBytes(totalBytes)} &middot; nothing leaves this network</div>
        </div>
      </div>
    </header>
    <ul>$rows</ul>
    <footer>
      <button class="all" onclick="downloadAll()">Download all</button>
      <div class="note">Files download straight from the other device.</div>
    </footer>
  </main>
  <script>
    const urls = ${jsonEncode(files.map((f) => _downloadUrl(sessionId, f.id)).toList())};
    function downloadAll() {
      urls.forEach((u, i) => setTimeout(() => {
        const a = document.createElement('a');
        a.href = u; a.download = '';
        document.body.appendChild(a); a.click(); a.remove();
      }, i * 400));
    }
  </script>
</body>
</html>''';
}

String _errorPage(int status) => '''
<!doctype html>
<html><head><meta charset="utf-8"><title>Sharely</title></head>
<body style="font-family:system-ui;background:#DCD6C8;color:#14120F;padding:40px;text-align:center">
<h1>Nothing to download</h1>
<p>This Sharely share isn't active (status $status).</p>
</body></html>''';
