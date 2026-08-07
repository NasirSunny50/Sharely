import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sharely/core/constants.dart';

/// User-configurable settings (alias, theme, language, save dir, port, PIN,
/// Quick Save, ask-before-accepting). Persisted with `shared_preferences`.
@immutable
class Settings {
  const Settings({
    this.alias = 'Sharely device',
    this.themeMode = ThemeMode.system,
    this.localeCode = 'system',
    this.saveDirPath,
    this.port = SharelyConstants.defaultPort,
    this.multicastGroup = SharelyConstants.multicastGroup,
    this.pin,
    this.askBeforeAccepting = true,
    this.quickSave = false,
    this.https = true,
    this.onboarded = false,
  });

  final String alias;
  final ThemeMode themeMode;

  /// 'en', 'bn', or 'system'.
  final String localeCode;
  final String? saveDirPath;
  final int port;
  final String multicastGroup;
  final String? pin;
  final bool askBeforeAccepting;
  final bool quickSave;
  final bool https;
  final bool onboarded;

  Locale? get locale => switch (localeCode) {
        'en' => const Locale('en'),
        'bn' => const Locale('bn'),
        _ => null,
      };

  Settings copyWith({
    String? alias,
    ThemeMode? themeMode,
    String? localeCode,
    String? saveDirPath,
    int? port,
    String? multicastGroup,
    Object? pin = _sentinel,
    bool? askBeforeAccepting,
    bool? quickSave,
    bool? https,
    bool? onboarded,
  }) {
    return Settings(
      alias: alias ?? this.alias,
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      saveDirPath: saveDirPath ?? this.saveDirPath,
      port: port ?? this.port,
      multicastGroup: multicastGroup ?? this.multicastGroup,
      pin: identical(pin, _sentinel) ? this.pin : pin as String?,
      askBeforeAccepting: askBeforeAccepting ?? this.askBeforeAccepting,
      quickSave: quickSave ?? this.quickSave,
      https: https ?? this.https,
      onboarded: onboarded ?? this.onboarded,
    );
  }
}

const Object _sentinel = Object();

/// Loads and persists [Settings]. Reads once at construction; writes on change.
class SettingsController extends StateNotifier<Settings> {
  SettingsController(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static Settings _read(SharedPreferences p) => Settings(
        alias: p.getString('alias') ?? 'Sharely device',
        themeMode: ThemeMode.values[p.getInt('themeMode') ?? 0],
        localeCode: p.getString('localeCode') ?? 'system',
        saveDirPath: p.getString('saveDirPath'),
        port: p.getInt('port') ?? SharelyConstants.defaultPort,
        multicastGroup:
            p.getString('multicastGroup') ?? SharelyConstants.multicastGroup,
        pin: p.getString('pin'),
        askBeforeAccepting: p.getBool('askBeforeAccepting') ?? true,
        quickSave: p.getBool('quickSave') ?? false,
        https: p.getBool('https') ?? true,
        onboarded: p.getBool('onboarded') ?? false,
      );

  Future<void> _persist(Settings s) async {
    await _prefs.setString('alias', s.alias);
    await _prefs.setInt('themeMode', s.themeMode.index);
    await _prefs.setString('localeCode', s.localeCode);
    if (s.saveDirPath != null) {
      await _prefs.setString('saveDirPath', s.saveDirPath!);
    }
    await _prefs.setInt('port', s.port);
    await _prefs.setString('multicastGroup', s.multicastGroup);
    if (s.pin != null) {
      await _prefs.setString('pin', s.pin!);
    } else {
      await _prefs.remove('pin');
    }
    await _prefs.setBool('askBeforeAccepting', s.askBeforeAccepting);
    await _prefs.setBool('quickSave', s.quickSave);
    await _prefs.setBool('https', s.https);
    await _prefs.setBool('onboarded', s.onboarded);
  }

  Future<void> update(Settings Function(Settings) mutate) async {
    final next = mutate(state);
    state = next;
    await _persist(next);
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      update((s) => s.copyWith(themeMode: mode));
  Future<void> setLocale(String code) =>
      update((s) => s.copyWith(localeCode: code));
  Future<void> setAlias(String alias) =>
      update((s) => s.copyWith(alias: alias));
  Future<void> setAskBeforeAccepting({required bool value}) =>
      update((s) => s.copyWith(askBeforeAccepting: value, quickSave: !value));
  Future<void> markOnboarded() => update((s) => s.copyWith(onboarded: true));
}

/// Injected in `main()` after `SharedPreferences` loads.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('override in main()'),
);

final settingsProvider =
    StateNotifierProvider<SettingsController, Settings>((ref) {
  return SettingsController(ref.watch(sharedPreferencesProvider));
});
