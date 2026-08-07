/// Human-readable formatting for sizes, speeds, and durations. Kept pure so it
/// can be unit-tested and used from either layer.
library;

class Format {
  const Format._();

  static const _units = ['B', 'KB', 'MB', 'GB', 'TB'];

  /// Formats a byte count, e.g. 324242 -> "316.6 KB".
  static String bytes(int value) {
    if (value < 1024) return '$value B';
    var size = value.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < _units.length - 1) {
      size /= 1024;
      unit++;
    }
    // Always one decimal for KB+ (matches the design, e.g. "184.2 MB").
    return '${size.toStringAsFixed(1)} ${_units[unit]}';
  }

  /// Formats a transfer speed in bytes/second, e.g. "12.6 MB/s".
  static String speed(double bytesPerSecond) =>
      '${bytes(bytesPerSecond.round())}/s';

  /// Formats a remaining duration compactly, e.g. "14.6 s" or "2m 05s".
  static String duration(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }
}
