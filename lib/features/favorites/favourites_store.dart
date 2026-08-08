import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// A trusted device that can skip the accept prompt.
@immutable
class FavouriteDevice {
  const FavouriteDevice({
    required this.fingerprint,
    required this.alias,
    this.autoAccept = true,
  });

  factory FavouriteDevice.fromJson(Map<String, dynamic> json) =>
      FavouriteDevice(
        fingerprint: json['fingerprint'] as String? ?? '',
        alias: json['alias'] as String? ?? '',
        autoAccept: json['autoAccept'] as bool? ?? true,
      );

  /// Identity — the device fingerprint (stable across sessions).
  final String fingerprint;
  final String alias;

  /// When true, transfers from this device are accepted without prompting.
  final bool autoAccept;

  FavouriteDevice copyWith({String? alias, bool? autoAccept}) => FavouriteDevice(
        fingerprint: fingerprint,
        alias: alias ?? this.alias,
        autoAccept: autoAccept ?? this.autoAccept,
      );

  Map<String, dynamic> toJson() => {
        'fingerprint': fingerprint,
        'alias': alias,
        'autoAccept': autoAccept,
      };
}

/// Persists favourite devices in a Hive box, keyed by fingerprint.
class FavouritesStore {
  FavouritesStore._(this._box);

  final Box<String> _box;
  static const _boxName = 'favourites';

  static Future<FavouritesStore> open() async {
    final box = await Hive.openBox<String>(_boxName);
    return FavouritesStore._(box);
  }

  List<FavouriteDevice> all() => _box.values
      .map((s) =>
          FavouriteDevice.fromJson(jsonDecode(s) as Map<String, dynamic>))
      .toList();

  bool isFavourite(String fingerprint) => _box.containsKey(fingerprint);

  /// Whether transfers from [fingerprint] should be auto-accepted.
  bool isAutoAccept(String fingerprint) {
    final raw = _box.get(fingerprint);
    if (raw == null) return false;
    return FavouriteDevice.fromJson(jsonDecode(raw) as Map<String, dynamic>)
        .autoAccept;
  }

  Future<void> add(FavouriteDevice device) =>
      _box.put(device.fingerprint, jsonEncode(device.toJson()));

  Future<void> remove(String fingerprint) => _box.delete(fingerprint);

  Future<void> toggle(FavouriteDevice device) async {
    if (isFavourite(device.fingerprint)) {
      await remove(device.fingerprint);
    } else {
      await add(device);
    }
  }

  Future<void> setAutoAccept(String fingerprint, {required bool value}) async {
    final raw = _box.get(fingerprint);
    if (raw == null) return;
    final device =
        FavouriteDevice.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    await add(device.copyWith(autoAccept: value));
  }

  Listenable get changes => _FavBoxListenable(_box);
}

class _FavBoxListenable extends ChangeNotifier {
  _FavBoxListenable(Box<String> box) {
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
final favouritesStoreProvider = Provider<FavouritesStore>(
  (ref) => throw UnimplementedError('override in main()'),
);
