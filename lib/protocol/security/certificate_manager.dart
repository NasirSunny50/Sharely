import 'dart:convert';
import 'dart:io';

import 'package:basic_utils/basic_utils.dart';
import 'package:crypto/crypto.dart';

/// Generates, persists, and serves the device's self-signed TLS identity.
///
/// Per spec (§6.2): in HTTPS mode the device **fingerprint is the SHA-256 hash
/// of the TLS certificate**. The certificate and key are generated once and
/// persisted so the fingerprint is stable across launches — otherwise Favorites
/// break on every restart.
///
/// Pure Dart: uses `dart:io` and pure-Dart crypto packages, no Flutter imports.
/// The app layer injects the storage directory (e.g. from `path_provider`).
class CertificateManager {
  CertificateManager({required this.storageDir});

  /// Directory where `cert.pem` and `key.pem` are persisted.
  final Directory storageDir;

  static const _certFileName = 'cert.pem';
  static const _keyFileName = 'key.pem';

  String? _certPem;
  String? _keyPem;
  String? _fingerprint;
  SecurityContext? _securityContext;

  /// PEM-encoded self-signed certificate. Valid after [ensureInitialized].
  String get certificatePem => _requireInit(_certPem);

  /// PEM-encoded RSA private key. Valid after [ensureInitialized].
  String get privateKeyPem => _requireInit(_keyPem);

  /// SHA-256 fingerprint of the certificate (lowercase hex, no separators) —
  /// this is what we announce in HTTPS mode (§6.2). Matches LocalSend's own
  /// `sha256(DER).toString()` format so peers pinning it interoperate.
  String get fingerprint => _requireInit(_fingerprint);

  /// A [SecurityContext] wrapping the cert+key, for the HTTPS shelf server.
  SecurityContext get securityContext {
    final ctx = _securityContext;
    if (ctx == null) {
      throw StateError('CertificateManager.ensureInitialized() not called');
    }
    return ctx;
  }

  File get _certFile => File('${storageDir.path}${Platform.pathSeparator}$_certFileName');
  File get _keyFile => File('${storageDir.path}${Platform.pathSeparator}$_keyFileName');

  /// Loads an existing identity from disk, or generates and persists a new one
  /// on first run. Idempotent — safe to call multiple times.
  Future<void> ensureInitialized() async {
    if (_certPem != null) return;

    if (!storageDir.existsSync()) {
      storageDir.createSync(recursive: true);
    }

    if (_certFile.existsSync() && _keyFile.existsSync()) {
      _certPem = await _certFile.readAsString();
      _keyPem = await _keyFile.readAsString();
    } else {
      final generated = _generate();
      _certPem = generated.certPem;
      _keyPem = generated.keyPem;
      await _certFile.writeAsString(_certPem!, flush: true);
      await _keyFile.writeAsString(_keyPem!, flush: true);
    }

    _fingerprint = computeFingerprint(_certPem!);
    _securityContext = SecurityContext()
      ..useCertificateChainBytes(utf8.encode(_certPem!))
      ..usePrivateKeyBytes(utf8.encode(_keyPem!));
  }

  /// Computes the SHA-256 fingerprint of a PEM certificate: hash the DER bytes
  /// (the base64 body between the PEM header/footer) and hex-encode. This is
  /// the exact format LocalSend uses.
  static String computeFingerprint(String certPem) {
    final der = _pemToDer(certPem);
    return sha256.convert(der).toString();
  }

  ({String certPem, String keyPem}) _generate() {
    final pair = CryptoUtils.generateRSAKeyPair();
    final privateKey = pair.privateKey as RSAPrivateKey;
    final publicKey = pair.publicKey as RSAPublicKey;

    // A self-signed cert needs a CSR to carry the subject DN. The values here
    // are cosmetic — peers identify us by fingerprint, not by DN.
    const dn = {
      'CN': 'Sharely',
      'O': 'Sharely',
      'OU': 'Sharely',
    };
    final csr = X509Utils.generateRsaCsrPem(dn, privateKey, publicKey);
    final certPem = X509Utils.generateSelfSignedCertificate(
      privateKey,
      csr,
      // ~100 years: this is a device identity, not a web PKI cert; it should
      // not silently expire and break transfers.
      365 * 100,
    );
    final keyPem = CryptoUtils.encodeRSAPrivateKeyToPem(privateKey);
    return (certPem: certPem, keyPem: keyPem);
  }

  static List<int> _pemToDer(String pem) {
    final body = pem
        .split('\n')
        .where((l) => !l.startsWith('-----'))
        .join()
        // Drop any CR / whitespace left by the PEM line wrapping.
        .replaceAll(RegExp(r'\s'), '');
    return base64.decode(body);
  }

  T _requireInit<T>(T? value) {
    if (value == null) {
      throw StateError('CertificateManager.ensureInitialized() not called');
    }
    return value;
  }
}
