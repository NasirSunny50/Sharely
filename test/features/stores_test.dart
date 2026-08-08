@Tags(['slow'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sharely/features/favorites/favourites_store.dart';
import 'package:sharely/features/history/history_store.dart';

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('sharely_hive');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  group('HistoryStore', () {
    test('adds records and returns them newest-first', () async {
      final store = await HistoryStore.open();
      await store.add(TransferRecord(
        id: 'a',
        direction: HistoryDirection.sent,
        deviceName: 'Phone',
        fileCount: 2,
        totalBytes: 100,
        at: DateTime(2026, 1, 1),
        success: true,
      ));
      await store.add(TransferRecord(
        id: 'b',
        direction: HistoryDirection.received,
        deviceName: 'Laptop',
        fileCount: 1,
        totalBytes: 50,
        at: DateTime(2026, 1, 2),
        success: true,
      ));

      final all = store.all();
      expect(all.length, 2);
      expect(all.first.id, 'b'); // newest first
      expect(all.first.direction, HistoryDirection.received);
    });

    test('survives reopen (persisted)', () async {
      final store = await HistoryStore.open();
      await store.add(TransferRecord(
        id: 'x',
        direction: HistoryDirection.sent,
        deviceName: 'P',
        fileCount: 1,
        totalBytes: 10,
        at: DateTime(2026),
        success: false,
      ));
      await Hive.close();

      final reopened = await HistoryStore.open();
      expect(reopened.all().single.success, isFalse);
    });
  });

  group('FavouritesStore', () {
    test('add / isFavourite / auto-accept toggle', () async {
      final store = await FavouritesStore.open();
      expect(store.isFavourite('fp1'), isFalse);
      expect(store.isAutoAccept('fp1'), isFalse);

      await store.add(const FavouriteDevice(
          fingerprint: 'fp1', alias: 'Rafi', autoAccept: true));
      expect(store.isFavourite('fp1'), isTrue);
      expect(store.isAutoAccept('fp1'), isTrue);

      await store.setAutoAccept('fp1', value: false);
      expect(store.isAutoAccept('fp1'), isFalse);
      expect(store.isFavourite('fp1'), isTrue); // still a favourite

      await store.remove('fp1');
      expect(store.isFavourite('fp1'), isFalse);
    });

    test('toggle adds then removes', () async {
      final store = await FavouritesStore.open();
      const d = FavouriteDevice(fingerprint: 'f', alias: 'A');
      await store.toggle(d);
      expect(store.isFavourite('f'), isTrue);
      await store.toggle(d);
      expect(store.isFavourite('f'), isFalse);
    });
  });
}
