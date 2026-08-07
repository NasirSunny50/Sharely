import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sharely/core/format.dart';
import 'package:sharely/design/app_palette.dart';
import 'package:sharely/design/components.dart';
import 'package:sharely/design/tokens.dart';
import 'package:sharely/features/network/network_controller.dart';
import 'package:sharely/l10n/generated/app_localizations.dart';
import 'package:sharely/protocol/models/file_dto.dart';

/// Wraps the app and shows the incoming-request sheet over any screen when a
/// peer asks to send (§ incoming request, with per-file partial accept).
class IncomingOverlay extends ConsumerWidget {
  const IncomingOverlay({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incoming = ref.watch(
      networkControllerProvider.select((s) => s.incoming),
    );
    return Stack(
      children: [
        child,
        if (incoming != null)
          _IncomingSheet(
            files: incoming.request.files.values.toList(),
            senderAlias: incoming.request.info.alias,
            deviceType: incoming.request.info.deviceType.name,
          ),
      ],
    );
  }
}

class _IncomingSheet extends ConsumerStatefulWidget {
  const _IncomingSheet({
    required this.files,
    required this.senderAlias,
    required this.deviceType,
  });
  final List<FileDto> files;
  final String senderAlias;
  final String deviceType;

  @override
  ConsumerState<_IncomingSheet> createState() => _IncomingSheetState();
}

class _IncomingSheetState extends ConsumerState<_IncomingSheet> {
  late final Set<String> _selected =
      widget.files.map((f) => f.id).toSet();

  int get _totalBytes => widget.files
      .where((f) => _selected.contains(f.id))
      .fold(0, (s, f) => s + f.size);

  void _respond(Set<String> ids) =>
      ref.read(networkControllerProvider.notifier).respondToIncoming(ids);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    return Material(
      color: p.scrim.withValues(alpha: 0.7),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.sheet)),
              boxShadow: AppElevation.sheet(dark: p.isDark),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenH),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: p.borderStrong,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l.incomingTitle(widget.senderAlias, widget.files.length),
                      style: AppText.heading.copyWith(color: p.ink),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    DataText(
                        '${widget.deviceType} · ${Format.bytes(_totalBytes)}',
                        style: AppText.dataSmall),
                    const SizedBox(height: AppSpacing.md),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: widget.files.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) {
                          final f = widget.files[i];
                          final sel = _selected.contains(f.id);
                          return AppCard(
                            onTap: () => setState(() {
                              if (sel) {
                                _selected.remove(f.id);
                              } else {
                                _selected.add(f.id);
                              }
                            }),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(f.fileName,
                                          style: AppText.body
                                              .copyWith(color: p.ink),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      DataText(Format.bytes(f.size),
                                          style: AppText.dataSmall),
                                    ],
                                  ),
                                ),
                                Icon(
                                  sel
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: sel ? p.primary : p.borderStrong,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(l.incomingUntick('Downloads/Sharely'),
                        style: AppText.caption.copyWith(color: p.muted)),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: l.actionReject,
                            onPressed: () => _respond(const {}),
                            height: 56,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          flex: 3,
                          child: PrimaryButton(
                            label: l.incomingAccept(_selected.length),
                            height: 56,
                            onPressed: _selected.isEmpty
                                ? null
                                : () => _respond(_selected),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
