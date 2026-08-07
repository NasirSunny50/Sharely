import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sharely/design/app_palette.dart';
import 'package:sharely/design/components.dart';
import 'package:sharely/design/tokens.dart';
import 'package:sharely/features/settings/settings_controller.dart';
import 'package:sharely/l10n/generated/app_localizations.dart';

/// Screen 30 — settings index.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return AppScaffold(
      body: ListView(
        children: [
          ScreenHeader(title: l.settingsTitle, onBack: () => context.pop()),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _Row(
                    title: l.settingsDeviceName,
                    value: settings.alias,
                    onTap: () {},
                  ),
                  _Divider(),
                  _Row(
                    title: l.settingsSaveTo,
                    value: settings.saveDirPath ?? 'Downloads/Sharely',
                    onTap: () {},
                  ),
                  _Divider(),
                  _ToggleRow(
                    title: l.settingsAskBeforeAccepting,
                    sub: l.settingsAskBeforeAcceptingSub,
                    value: settings.askBeforeAccepting,
                    onChanged: (v) => controller.setAskBeforeAccepting(value: v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ThemeRow(
                    current: settings.themeMode,
                    onChanged: controller.setThemeMode,
                  ),
                  _Divider(),
                  _LanguageRow(
                    current: settings.localeCode,
                    onChanged: controller.setLocale,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _Row(
                    title: l.settingsSecurity,
                    value: l.pinSetTitle,
                    onTap: () => context.push('/pin'),
                  ),
                  _Divider(),
                  _Row(
                    title: l.troubleshootTitle,
                    value: '',
                    onTap: () => context.push('/settings/troubleshooting'),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            child: Text(l.settingsPrivacyNote,
                style: AppText.caption.copyWith(color: p.mutedLight)),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: context.palette.border);
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.value, required this.onTap});
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.bodyLarge.copyWith(color: p.ink)),
                  Text(value,
                      style: AppText.caption.copyWith(color: p.mutedLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: p.mutedLight),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.sub,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.bodyLarge.copyWith(color: p.ink)),
                Text(sub,
                    style: AppText.caption.copyWith(color: p.mutedLight)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: p.onPrimary,
            activeTrackColor: p.primary,
          ),
        ],
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow({required this.current, required this.onChanged});
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
              child: Text(l.settingsAppearance,
                  style: AppText.bodyLarge.copyWith(color: p.ink))),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(value: ThemeMode.light, label: Text(l.settingsThemeLight)),
              ButtonSegment(value: ThemeMode.dark, label: Text(l.settingsThemeDark)),
              ButtonSegment(value: ThemeMode.system, label: Text(l.settingsThemeSystem)),
            ],
            selected: {current},
            showSelectedIcon: false,
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.current, required this.onChanged});
  final String current;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
              child: Text(l.settingsLanguage,
                  style: AppText.bodyLarge.copyWith(color: p.ink))),
          DropdownButton<String>(
            value: current,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'system', child: Text('System')),
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'bn', child: Text('বাংলা')),
            ],
            onChanged: (v) => v == null ? null : onChanged(v),
          ),
        ],
      ),
    );
  }
}
