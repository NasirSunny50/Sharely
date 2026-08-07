@Tags(['slow']) // RSA keygen
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sharely/protocol/security/certificate_manager.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('sharely_cert_test');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('generates a cert + key and a hex SHA-256 fingerprint on first run',
      () async {
    final mgr = CertificateManager(storageDir: tmp);
    await mgr.ensureInitialized();

    expect(mgr.certificatePem, contains('BEGIN CERTIFICATE'));
    expect(mgr.privateKeyPem, contains('BEGIN'));
    // SHA-256 hex = 64 lowercase hex chars, no separators (LocalSend format).
    expect(mgr.fingerprint, matches(RegExp(r'^[0-9a-f]{64}$')));

    // Files persisted.
    expect(File('${tmp.path}${Platform.pathSeparator}cert.pem').existsSync(),
        isTrue);
    expect(File('${tmp.path}${Platform.pathSeparator}key.pem').existsSync(),
        isTrue);
  });

  test('fingerprint is stable across restarts (reload from disk)', () async {
    final first = CertificateManager(storageDir: tmp);
    await first.ensureInitialized();
    final fp1 = first.fingerprint;
    final cert1 = first.certificatePem;

    // Simulate a fresh launch: a brand-new manager over the same directory.
    final second = CertificateManager(storageDir: tmp);
    await second.ensureInitialized();

    expect(second.fingerprint, fp1);
    expect(second.certificatePem, cert1); // did not regenerate
  });

  test('computeFingerprint matches the manager fingerprint', () async {
    final mgr = CertificateManager(storageDir: tmp);
    await mgr.ensureInitialized();
    expect(
      CertificateManager.computeFingerprint(mgr.certificatePem),
      mgr.fingerprint,
    );
  });

  test('accessing state before init throws', () {
    final mgr = CertificateManager(storageDir: tmp);
    expect(() => mgr.fingerprint, throwsStateError);
    expect(() => mgr.securityContext, throwsStateError);
  });
}
