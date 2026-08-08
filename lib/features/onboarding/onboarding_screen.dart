import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sharely/design/app_palette.dart';
import 'package:sharely/design/components.dart';
import 'package:sharely/design/tokens.dart';
import 'package:sharely/features/settings/settings_controller.dart';
import 'package:sharely/l10n/generated/app_localizations.dart';
import 'package:sharely/platform/permissions.dart';

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
                const _PermissionsBeat(),
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

/// The Permissions beat — explains each permission in the user's terms, then
/// fires the real OS dialogs and reflects what was granted.
class _PermissionsBeat extends StatefulWidget {
  const _PermissionsBeat();

  @override
  State<_PermissionsBeat> createState() => _PermissionsBeatState();
}

class _PermissionsBeatState extends State<_PermissionsBeat> {
  static const _service = PermissionsService();
  Map<SharelyPermission, bool> _granted = const {};
  bool _requesting = false;

  Future<void> _requestAll() async {
    setState(() => _requesting = true);
    final result = await _service.requestOnboarding();
    if (mounted) {
      setState(() {
        _granted = result;
        _requesting = false;
      });
    }
  }

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
          Text(l.onbPermTitle,
              style: AppText.titleLarge.copyWith(color: p.ink)),
          const SizedBox(height: AppSpacing.sm),
          Text(l.onbPermBody, style: AppText.body.copyWith(color: p.muted)),
          const SizedBox(height: AppSpacing.xl),
          _PermRow(
            icon: Icons.notifications_outlined,
            title: l.permNotifications,
            why: l.permNotificationsWhy,
            granted: _granted[SharelyPermission.notifications],
          ),
          const SizedBox(height: AppSpacing.md),
          _PermRow(
            icon: Icons.wifi_tethering,
            title: l.permNearby,
            why: l.permNearbyWhy,
            granted: _granted[SharelyPermission.nearbyDevices],
          ),
          const SizedBox(height: AppSpacing.md),
          _PermRow(
            icon: Icons.photo_camera_outlined,
            title: l.permCamera,
            why: l.permCameraWhy,
            granted: null, // asked at point of use (opening the scanner)
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_granted.isEmpty)
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: l.permGrant,
                onPressed: _requesting ? null : _requestAll,
              ),
            ),
        ],
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  const _PermRow({
    required this.icon,
    required this.title,
    required this.why,
    required this.granted,
  });
  final IconData icon;
  final String title;
  final String why;
  final bool? granted;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: p.cardSunken,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: p.inkSecondary, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.bodyLarge.copyWith(color: p.ink)),
              Text(why,
                  style: AppText.caption.copyWith(color: p.muted),
                  maxLines: 2),
            ],
          ),
        ),
        if (granted == true)
          Row(
            children: [
              Icon(Icons.check_circle, color: p.success, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(l.permGranted,
                  style: AppText.caption.copyWith(color: p.successText)),
            ],
          ),
      ],
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
