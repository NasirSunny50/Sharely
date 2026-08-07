/// Local, ring-buffered file logger.
///
/// No telemetry, no analytics, no crash-reporting SDK (see PROMPT.md §2.3).
/// This writes only to an on-device file the user can view and clear.
///
/// This file is intentionally pure Dart with no Flutter imports so the
/// protocol layer can log without pulling in the widget layer. The file
/// location is injected by the app layer via the [SharelyLogger.sink] setter.
library;

import 'dart:collection';

enum LogLevel { debug, info, warn, error }

/// A single log entry held in the in-memory ring buffer.
class LogEntry {
  const LogEntry(this.time, this.level, this.tag, this.message);

  final DateTime time;
  final LogLevel level;
  final String tag;
  final String message;

  @override
  String toString() =>
      '${time.toIso8601String()} [${level.name.toUpperCase()}] $tag: $message';
}

/// Process-wide logger. Keeps the last [maxEntries] entries in memory and
/// optionally appends to a sink configured by the app layer.
class SharelyLogger {
  SharelyLogger._();
  static final SharelyLogger instance = SharelyLogger._();

  static const int maxEntries = 2000;

  final Queue<LogEntry> _buffer = Queue<LogEntry>();

  /// Sink for durable output (a file writer set up by the app layer). Kept as
  /// a plain callback so this file stays Flutter- and dart:io-free at import
  /// time; callers on platforms without a filesystem simply skip it.
  /// The durable output sink (a file writer set up by the app layer).
  void Function(LogEntry entry)? sink;

  UnmodifiableListView<LogEntry> get entries =>
      UnmodifiableListView(_buffer);

  void clear() => _buffer.clear();

  void log(LogLevel level, String tag, String message) {
    final entry = LogEntry(DateTime.now(), level, tag, message);
    _buffer.add(entry);
    while (_buffer.length > maxEntries) {
      _buffer.removeFirst();
    }
    sink?.call(entry);
  }

  void d(String tag, String message) => log(LogLevel.debug, tag, message);
  void i(String tag, String message) => log(LogLevel.info, tag, message);
  void w(String tag, String message) => log(LogLevel.warn, tag, message);
  void e(String tag, String message) => log(LogLevel.error, tag, message);
}
