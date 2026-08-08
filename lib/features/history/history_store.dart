import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Direction of a past transfer relative to this device.
enum HistoryDirection { sent, received }

/// One row in the transfer history.
@immutable
class TransferRecord {
  const TransferRecord({
    required this.id,
    required this.direction,
    required this.deviceName,
    required this.fileCount,
    required this.totalBytes,
    required this.at,
    required this.success,
    this.firstFileName,
  });

  factory TransferRecord.fromJson(Map<String, dynamic> json) => TransferRecord(
        id: json['id'] as String,
        direction: HistoryDirection.values.firstWhere(
          (d) => d.name == json['direction'],
          orElse: () => HistoryDirection.sent,
        ),
        deviceName: json['deviceName'] as String? ?? '',
        fileCount: (json['fileCount'] as num?)?.toInt() ?? 0,
        totalBytes: (json['totalBytes'] as num?)?.toInt() ?? 0,
        at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
        success: json['success'] as bool? ?? true,
        firstFileName: json['firstFileName'] as String?,
      );

  final String id;
  final HistoryDirection direction;
  final String deviceName;
  final int fileCount;
  final int totalBytes;
  final DateTime at;
  final bool success;
  final String? firstFileName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'direction': direction.name,
        'deviceName': deviceName,
        'fileCount': fileCount,
        'totalBytes': totalBytes,
        'at': at.toIso8601String(),
        'success': success,
        'firstFileName': firstFileName,
      };
}

/// Persists transfer history in a Hive box (records stored as JSON strings so
/// no code-gen adapters are needed). Newest first.
class HistoryStore {
  HistoryStore._(this._box);

  final Box<String> _box;
  static const _boxName = 'history';

  static Future<HistoryStore> open() async {
    final box = await Hive.openBox<String>(_boxName);
    return HistoryStore._(box);
  }

  /// All records, newest first.
  List<TransferRecord> all() {
    final records = _box.values
        .map((s) => TransferRecord.fromJson(
            jsonDecode(s) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    return records;
  }

  Future<void> add(TransferRecord record) =>
      _box.put(record.id, jsonEncode(record.toJson()));

  Future<void> clear() => _box.clear();

  /// A change notifier so the UI can rebuild when history changes.
  Listenable get changes => _HiveBoxListenable(_box);
}

/// Adapts a Hive box's watch stream to [Listenable] without the hive_flutter
/// dependency in this pure store file.
class _HiveBoxListenable extends ChangeNotifier {
  _HiveBoxListenable(Box<String> box) {
    _sub = box.watch().listen((_) => notifyListeners());
  }
  Object? _sub;
  @override
  void dispose() {
    (_sub as dynamic)?.cancel();
    super.dispose();
  }
}

/// Overridden in main() after the box opens.
final historyStoreProvider = Provider<HistoryStore>(
  (ref) => throw UnimplementedError('override in main()'),
);
