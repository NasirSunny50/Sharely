import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sharely/features/settings/settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> freshPrefs([Map<String, Object>? initial]) async {
    SharedPreferences.setMockInitialValues(initial ?? {});
    return SharedPreferences.getInstance();
  }

  test('locale persists and reloads across a fresh controller', () async {
    final prefs = await freshPrefs();
    final c1 = SettingsController(prefs);
    await c1.setLocale('bn');

    // A brand-new controller over the SAME prefs = an app restart.
    final c2 = SettingsController(prefs);
    expect(c2.state.localeCode, 'bn');
    expect(c2.state.locale, const Locale('bn'));
  });

  test('theme + locale together both survive a restart', () async {
    final prefs = await freshPrefs();
    final c1 = SettingsController(prefs);
    await c1.setThemeMode(ThemeMode.dark);
    await c1.setLocale('bn');

    final c2 = SettingsController(prefs);
    expect(c2.state.themeMode, ThemeMode.dark);
    expect(c2.state.localeCode, 'bn');
  });

  test('written keys are actually in the store (durable across getInstance)',
      () async {
    final prefs = await freshPrefs();
    await SettingsController(prefs).setLocale('bn');

    // Re-fetch the singleton — simulates the next launch reading from disk.
    final reloaded = await SharedPreferences.getInstance();
    expect(reloaded.getString('localeCode'), 'bn');
  });
}
