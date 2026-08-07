import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sharely/design/app_palette.dart';
import 'package:sharely/design/components.dart';
import 'package:sharely/design/tokens.dart';
import 'package:sharely/features/settings/settings_controller.dart';
import 'package:sharely/l10n/generated/app_localizations.dart';

/// Onboarding — 4 beats: welcome, name this device, permissions, how it works.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  final _nameController = TextEditingController();
  int _page = 0;

  static const _pages = 4;

  @override
  void initState() {
    super.initState();
    _nameController.text = ref.read(settingsProvider).alias;
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page < _pages - 1) {
      await _controller.nextPage(
          duration: AppMotion.medium, curve: AppMotion.standard);
    } else {
      final controller = ref.read(settingsProvider.notifier);
      await controller.setAlias(_nameController.text.trim());
      await controller.markOnboarded();
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    return AppScaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                _Beat(
                  icon: Icons.swap_horiz,
                  title: l.appName,
                  body: l.homePrivacyLine,
                ),
                _NameBeat(controller: _nameController),
                _Beat(
                  icon: Icons.wifi_tethering,
                  title: l.settingsNetwork,
                  body: l.homeNothingFoundHint,
                ),
                _Beat(
                  icon: Icons.bolt,
                  title: l.homeSendSomething,
                  body: l.hubTextSub,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            child: Row(
              children: [
                Row(
                  children: List.generate(
                    _pages,
                    (i) => AnimatedContainer(
                      duration: AppMotion.fast,
                      margin: const EdgeInsets.only(right: AppSpacing.xs),
                      width: i == _page ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? p.primary : p.borderStrong,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 160,
                  child: PrimaryButton(
                    label: _page < _pages - 1
                        ? l.actionContinue
                        : l.actionDone,
                    onPressed: _next,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Beat extends StatelessWidget {
  const _Beat({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.huge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: p.ink,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              boxShadow: [
                BoxShadow(color: p.primary, offset: const Offset(0, 6)),
              ],
            ),
            child: Icon(icon, color: p.surface, size: 44),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(title, style: AppText.titleLarge.copyWith(color: p.ink)),
          const SizedBox(height: AppSpacing.md),
          Text(body, style: AppText.body.copyWith(color: p.muted)),
        ],
      ),
    );
  }
}

class _NameBeat extends StatelessWidget {
  const _NameBeat({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.huge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.settingsDeviceName,
              style: AppText.titleLarge.copyWith(color: p.ink)),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            style: AppText.bodyLarge.copyWith(color: p.ink),
            decoration: InputDecoration(
              filled: true,
              fillColor: p.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: p.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: p.border),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
