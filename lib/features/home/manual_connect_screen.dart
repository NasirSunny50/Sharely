import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sharely/design/app_palette.dart';
import 'package:sharely/design/components.dart';
import 'package:sharely/design/tokens.dart';
import 'package:sharely/l10n/generated/app_localizations.dart';

/// Screen 8 — manual connect (IP entry / QR), the escape hatch for hostile
/// networks where auto-discovery fails.
class ManualConnectScreen extends StatefulWidget {
  const ManualConnectScreen({super.key});

  @override
  State<ManualConnectScreen> createState() => _ManualConnectScreenState();
}

class _ManualConnectScreenState extends State<ManualConnectScreen> {
  final _ip = TextEditingController();

  @override
  void dispose() {
    _ip.dispose();
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
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.manualConnectBody,
                    style: AppText.body.copyWith(color: p.muted)),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _ip,
                  keyboardType: TextInputType.number,
                  style: AppText.data.copyWith(color: p.ink),
                  decoration: InputDecoration(
                    hintText: l.manualConnectHint,
                    filled: true,
                    fillColor: p.card,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide(color: p.border),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide(color: p.border),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: l.actionContinue,
                  onPressed: _ip.text.isEmpty ? null : () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
