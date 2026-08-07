import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sharely/protocol/server/file_writer.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('sharely_fw'));
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<String> writeFile(String name, List<int> bytes) async {
    final f = ReceivingFile(saveDir: dir, fileName: name, expectedSize: bytes.length);
    await f.open();
    if (bytes.isNotEmpty) await f.writeChunk(bytes);
    await f.finish();
    return f.path!;
  }

  test('writes a simple file to disk', () async {
    final path = await writeFile('hello.txt', [1, 2, 3]);
    expect(p.basename(path), 'hello.txt');
    expect(File(path).readAsBytesSync(), [1, 2, 3]);
  });

  test('a 0-byte file is created and complete', () async {
    final f = ReceivingFile(saveDir: dir, fileName: 'empty.bin', expectedSize: 0);
    await f.open();
    await f.finish();
    expect(File(f.path!).existsSync(), isTrue);
    expect(File(f.path!).lengthSync(), 0);
    expect(f.isComplete, isTrue);
  });

  test('a file with no extension collides to " (1)"', () async {
    await writeFile('README', [1]);
    final second = await writeFile('README', [2]);
    expect(p.basename(second), 'README (1)');
  });

  test('two identical names in a batch keep both', () async {
    final a = await writeFile('dup.txt', [1]);
    final b = await writeFile('dup.txt', [2]);
    final c = await writeFile('dup.txt', [3]);
    expect(p.basename(a), 'dup.txt');
    expect(p.basename(b), 'dup (1).txt');
    expect(p.basename(c), 'dup (2).txt');
  });

  test('path-traversal names are sanitized to stay inside saveDir', () async {
    final path = await writeFile('../../etc/evil.txt', [9]);
    // Must resolve to a direct child of saveDir, not an escaped path.
    expect(p.dirname(path), dir.path);
    expect(p.basename(path), 'evil.txt');
  });

  test('reserved characters are replaced', () async {
    final path = await writeFile('a:b*c?.txt', [1]);
    final name = p.basename(path);
    expect(name, isNot(contains(':')));
    expect(name, isNot(contains('*')));
    expect(name, isNot(contains('?')));
  });

  test('emoji and Bangla filenames are preserved', () async {
    final emoji = await writeFile('photo😀.png', [1]);
    final bangla = await writeFile('ছবি.png', [2]);
    expect(p.basename(emoji), 'photo😀.png');
    expect(p.basename(bangla), 'ছবি.png');
  });

  test('a 300-character filename is handled', () async {
    final long = '${'x' * 296}.txt';
    final path = await writeFile(long, [1]);
    expect(File(path).existsSync(), isTrue);
  });

  test('abort deletes the partial file', () async {
    final f = ReceivingFile(saveDir: dir, fileName: 'partial.bin', expectedSize: 1000);
    await f.open();
    await f.writeChunk(List.filled(100, 7));
    final path = f.path!;
    expect(File(path).existsSync(), isTrue);
    await f.abort();
    expect(File(path).existsSync(), isFalse);
  });
}
