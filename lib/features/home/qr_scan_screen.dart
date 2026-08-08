import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sharely/design/app_palette.dart';
import 'package:sharely/design/components.dart';
import 'package:sharely/design/tokens.dart';
import 'package:sharely/l10n/generated/app_localizations.dart';
import 'package:sharely/platform/permissions.dart';

/// A QR scanner. Requests the camera permission at the point of use (best
/// practice), shows a plain-language reason if denied, and pops with the
/// scanned string via [Navigator.pop].
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  static const _permissions = PermissionsService();
  MobileScannerController? _controller;
  bool _denied = false;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    unawaited(_ensureCamera());
  }

  Future<void> _ensureCamera() async {
    final granted = await _permissions.requestCamera();
    if (!mounted) return;
    if (granted) {
      setState(() => _controller = MobileScannerController());
    } else {
      setState(() => _denied = true);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final value = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (value == null) return;
    _handled = true;
    context.pop(value);
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(title: l.manualConnectTitle, onBack: () => context.pop()),
          Expanded(
            child: _denied
                ? _DeniedView(onOpenSettings: _permissions.openSettings)
                : _controller == null
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                        padding: const EdgeInsets.all(AppSpacing.screenH),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppRadius.xxl),
                          child: MobileScanner(
                            controller: _controller,
                            onDetect: _onDetect,
                          ),
                        ),
                      ),
          ),
          if (!_denied && _controller != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              child: Text(l.manualConnectBody,
                  style: AppText.body.copyWith(color: p.muted),
                  textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }
}

class _DeniedView extends StatelessWidget {
  const _DeniedView({required this.onOpenSettings});
  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.huge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_camera_outlined, size: 44, color: p.muted),
            const SizedBox(height: AppSpacing.lg),
            Text(l.permCameraNeeded,
                style: AppText.body.copyWith(color: p.ink),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            SecondaryButton(
              label: l.permOpenSettings,
              onPressed: onOpenSettings,
            ),
          ],
        ),
      ),
    );
  }
}
