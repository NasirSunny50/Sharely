import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sharely/app.dart';
import 'package:sharely/features/settings/settings_controller.dart';

// The history/favourites stores are read lazily (only when devices/records
// exist), so these boot tests don't need them wired — keeping the test free of
// real Hive I/O, which would deadlock under testWidgets' fake-async zone.
Future<Widget> _app(Map<String, Object> prefsValues) async {
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const SharelyApp(),
  );
}

void main() {
  void usePhoneSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('a fresh install lands on onboarding', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(await _app({}));
    await tester.pump();
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('an onboarded install lands on Home with the send CTA',
      (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(await _app({'onboarded': true}));
    await tester.pump();
    expect(find.text('Send something'), findsOneWidget);
  });
}
