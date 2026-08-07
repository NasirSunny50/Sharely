import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sharely/design/app_palette.dart';
import 'package:sharely/design/components.dart';
import 'package:sharely/design/tokens.dart';
import 'package:sharely/features/settings/settings_controller.dart';
import 'package:sharely/l10n/generated/app_localizations.dart';

/// Screens 25/26 — set / enter a 6-digit PIN. [enterMode] toggles between
/// setting a PIN (settings) and entering one (sender side); [onSubmit] receives
/// the entered digits. In set mode the PIN is saved to settings.
class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({this.enterMode = false, this.onSubmit, super.key});
  final bool enterMode;
  final ValueChanged<String>? onSubmit;

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = '';
  bool _error = false;

  void _tap(int digit) {
    if (_pin.length >= 6) return;
    setState(() {
      _pin += '$digit';
      _error = false;
    });
    if (_pin.length == 6) unawaited(_submit());
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    if (widget.enterMode) {
      widget.onSubmit?.call(_pin);
    } else {
      await ref
          .read(settingsProvider.notifier)
          .update((s) => s.copyWith(pin: _pin));
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    return AppScaffold(
      body: Column(
        children: [
          ScreenHeader(
            title: widget.enterMode ? l.pinEnterTitle : l.pinSetTitle,
            onBack: () => context.pop(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(widget.enterMode ? '' : l.pinSetBody,
              style: AppText.body.copyWith(color: p.muted),
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              final filled = i < _pin.length;
              return Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? p.primary : Colors.transparent,
                  border: Border.all(
                      color: _error ? p.primary : p.borderStrong, width: 2),
                ),
              );
            }),
          ),
          if (_error)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(l.pinWrong,
                  style: AppText.label.copyWith(color: p.primary)),
            ),
          const Spacer(),
          _Keypad(onDigit: _tap, onBackspace: _backspace),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onBackspace});
  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget key(String label, {VoidCallback? onTap, IconData? icon}) => InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            height: 64,
            alignment: Alignment.center,
            child: icon != null
                ? Icon(icon, color: p.ink)
                : Text(label,
                    style: AppText.dataLarge
                        .copyWith(color: p.ink, fontSize: 28)),
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.huge),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.8,
        children: [
          for (var i = 1; i <= 9; i++)
            key('$i', onTap: () => onDigit(i)),
          const SizedBox.shrink(),
          key('0', onTap: () => onDigit(0)),
          key('', icon: Icons.backspace_outlined, onTap: onBackspace),
        ],
      ),
    );
  }
}
