import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:sharely/core/format.dart';
import 'package:sharely/design/app_palette.dart';
import 'package:sharely/design/components.dart';
import 'package:sharely/design/tokens.dart';
import 'package:sharely/features/history/history_store.dart';
import 'package:sharely/features/network/network_controller.dart';
import 'package:sharely/features/send/widgets/handoff.dart';
import 'package:sharely/l10n/generated/app_localizations.dart';
import 'package:sharely/protocol/client/send_service.dart';
import 'package:sharely/protocol/discovery/discovered_device.dart';
import 'package:sharely/protocol/models/file_dto.dart';
import 'package:sharely/protocol/server/download_session_manager.dart';

enum _Step { hub, review, sending, complete, failed }

/// Hosts the whole send flow as an internal step machine: choose what to send →
/// review → sending (with the Handoff) → complete/failed.
class SendFlow extends ConsumerStatefulWidget {
  const SendFlow({required this.target, super.key});
  final DiscoveredDevice? target;

  @override
  ConsumerState<SendFlow> createState() => _SendFlowState();
}

class _SendFlowState extends ConsumerState<SendFlow> {
  _Step _step = _Step.hub;
  final List<_PickedFile> _files = [];
  SendProgress? _progress;
  SendFailure? _failure;

  int get _totalBytes => _files.fold(0, (s, f) => s + f.size);

  Future<void> _pickFiles() async {
    final picked = await openFiles();
    if (picked.isEmpty) return;
    for (final x in picked) {
      final len = await File(x.path).length();
      _files.add(_PickedFile(path: x.path, name: x.name, size: len));
    }
    if (mounted) setState(() => _step = _Step.review);
  }

  /// Browser/reverse mode: pick files, host them over plain HTTP, and show the
  /// QR/URL screen for a receiver who has no app (§6.5).
  Future<void> _hostBrowser() async {
    final router = GoRouter.of(context);
    final picked = await openFiles();
    if (picked.isEmpty) return;
    final files = <DownloadableFile>[];
    for (final x in picked) {
      final len = await File(x.path).length();
      files.add(
        DownloadableFile(
          dto: FileDto(
            id: p.basename(x.path) + len.toString(),
            fileName: x.name,
            size: len,
            fileType: 'application/octet-stream',
          ),
          openRead: () => File(x.path).openRead(),
        ),
      );
    }
    await ref
        .read(networkControllerProvider.notifier)
        .startBrowserMode(files);
    if (mounted) await router.push('/browser');
  }

  Future<void> _startSend() async {
    final target = widget.target;
    final service = ref.read(networkControllerProvider.notifier).sendService;
    if (target == null || service == null) {
      setState(() {
        _failure = SendFailure.network;
        _step = _Step.failed;
      });
      return;
    }
    setState(() => _step = _Step.sending);

    final sub = service.progress.listen((pr) {
      if (mounted) setState(() => _progress = pr);
    });

    final outgoing = _files
        .map((f) => OutgoingFile(
              dto: FileDto(
                id: f.id,
                fileName: f.name,
                size: f.size,
                fileType: 'application/octet-stream',
              ),
              openRead: () => File(f.path).openRead(),
            ))
        .toList();

    final result = await service.send(
      baseUrl: target.baseUrl,
      target: target.info,
      files: outgoing,
    );
    await sub.cancel();
    if (!mounted) return;

    // Record the outcome in history.
    unawaited(ref.read(historyStoreProvider).add(TransferRecord(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          direction: HistoryDirection.sent,
          deviceName: target.info.alias,
          fileCount: _files.length,
          totalBytes: _totalBytes,
          at: DateTime.now(),
          success: result is SendSucceeded,
          firstFileName: _files.isEmpty ? null : _files.first.name,
        )));

    setState(() {
      if (result is SendSucceeded) {
        _step = _Step.complete;
      } else if (result is SendFailed) {
        _failure = result.failure;
        _step = _Step.failed;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: switch (_step) {
        _Step.hub => _HubView(
            targetName: widget.target?.info.alias,
            onPickFiles: _pickFiles,
            onBrowserMode: _hostBrowser,
            onBack: () => context.pop(),
          ),
        _Step.review => _ReviewView(
            files: _files,
            totalBytes: _totalBytes,
            targetName: widget.target?.info.alias ?? '—',
            onRemove: (f) => setState(() => _files.remove(f)),
            onBack: () => setState(() => _step = _Step.hub),
            onSend: _startSend,
          ),
        _Step.sending => _SendingView(
            progress: _progress,
            fileCount: _files.length,
            onCancel: () async {
              await ref
                  .read(networkControllerProvider.notifier)
                  .sendService
                  ?.cancel();
              if (context.mounted) context.pop();
            },
          ),
        _Step.complete => _CompleteView(
            fileCount: _files.length,
            targetName: widget.target?.info.alias ?? '—',
            onDone: () => context.pop(),
          ),
        _Step.failed => _FailedView(
            failure: _failure,
            onRetry: () => setState(() => _step = _Step.review),
            onBack: () => context.pop(),
          ),
      },
    );
  }
}

class _PickedFile {
  _PickedFile({required this.path, required this.name, required this.size})
      : id = p.basename(path) + size.toString();
  final String id;
  final String path;
  final String name;
  final int size;
}

class _HubView extends StatelessWidget {
  const _HubView({
    required this.targetName,
    required this.onPickFiles,
    required this.onBrowserMode,
    required this.onBack,
  });
  final String? targetName;
  final VoidCallback onPickFiles;
  final VoidCallback onBrowserMode;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScreenHeader(
          title: targetName != null ? l.sendToTitle(targetName!) : l.actionSend,
          onBack: onBack,
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.35,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _HubCard(
                  icon: Icons.photo_library_outlined,
                  title: l.hubPhotos,
                  sub: l.hubFilesSub,
                  onTap: onPickFiles,
                  accent: true),
              _HubCard(
                  icon: Icons.insert_drive_file_outlined,
                  title: l.hubFiles,
                  sub: l.hubFilesSub,
                  onTap: onPickFiles),
              _HubCard(
                  icon: Icons.folder_outlined,
                  title: l.hubFolders,
                  sub: l.hubFoldersSub,
                  onTap: onPickFiles),
              _HubCard(
                  icon: Icons.grid_view_outlined,
                  title: l.hubApps,
                  sub: l.hubAppsSub,
                  onTap: onPickFiles),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: AppCard(
            onTap: onBrowserMode,
            child: Row(
              children: [
                Icon(Icons.qr_code_2, color: p.inkSecondary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.browserWaitingTitle,
                          style: AppText.bodyLarge.copyWith(color: p.ink)),
                      Text(l.browserWaitingBody,
                          style: AppText.caption.copyWith(color: p.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
    this.accent = false,
  });
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 26, color: accent ? p.primary : p.inkSecondary),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.bodyLarge.copyWith(color: p.ink)),
              Text(sub,
                  style: AppText.caption.copyWith(color: p.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewView extends StatelessWidget {
  const _ReviewView({
    required this.files,
    required this.totalBytes,
    required this.targetName,
    required this.onRemove,
    required this.onBack,
    required this.onSend,
  });
  final List<_PickedFile> files;
  final int totalBytes;
  final String targetName;
  final void Function(_PickedFile) onRemove;
  final VoidCallback onBack;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScreenHeader(title: l.reviewTitle, onBack: onBack),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenH,
              AppSpacing.lg, AppSpacing.screenH, AppSpacing.sm),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: p.ink,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.reviewGoingTo.toUpperCase(),
                          style: AppText.badge.copyWith(color: p.mutedLight)),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(targetName,
                          style: AppText.heading.copyWith(color: p.surface)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.reviewFilesCount(files.length),
                  style: AppText.bodyLarge.copyWith(color: p.ink)),
              DataText(Format.bytes(totalBytes)),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            itemCount: files.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final f = files[i];
              return AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.name,
                              style: AppText.body.copyWith(color: p.ink),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          DataText(Format.bytes(f.size),
                              style: AppText.dataSmall),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 16, color: p.muted),
                      onPressed: () => onRemove(f),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: PrimaryButton(
            label: l.actionSend,
            onPressed: files.isEmpty ? null : onSend,
          ),
        ),
      ],
    );
  }
}

class _SendingView extends StatelessWidget {
  const _SendingView({
    required this.progress,
    required this.fileCount,
    required this.onCancel,
  });
  final SendProgress? progress;
  final int fileCount;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final frac = progress?.session.fraction ?? 0;
    final pct = (frac * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenH,
              AppSpacing.md, AppSpacing.screenH, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.actionSending, style: AppText.title.copyWith(color: p.ink)),
              SecondaryButton(label: l.actionCancel, onPressed: onCancel, height: 36),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Expanded(child: HandoffAnimation()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$pct',
                  style: AppText.dataLarge.copyWith(color: p.ink)),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('%',
                    style: AppText.mono.copyWith(color: p.mutedLight, fontSize: 16)),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  DataText(
                    Format.speed(progress?.bytesPerSecond ?? 0),
                    style: AppText.data,
                    color: p.ink,
                  ),
                  DataText(
                    progress == null
                        ? '—'
                        : l.sendingEta(Format.duration(progress!.eta)),
                    style: AppText.dataSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenH,
              AppSpacing.md, AppSpacing.screenH, AppSpacing.xxl),
          child: AppProgressBar(fraction: frac),
        ),
      ],
    );
  }
}

class _CompleteView extends StatelessWidget {
  const _CompleteView({
    required this.fileCount,
    required this.targetName,
    required this.onDone,
  });
  final int fileCount;
  final String targetName;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(child: HandoffComplete()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Text(
            l.completeTitle(fileCount, targetName),
            style: AppText.titleLarge.copyWith(color: p.ink),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: PrimaryButton(label: l.actionDone, onPressed: onDone),
        ),
      ],
    );
  }
}

class _FailedView extends StatelessWidget {
  const _FailedView({
    required this.failure,
    required this.onRetry,
    required this.onBack,
  });
  final SendFailure? failure;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final message = switch (failure) {
      SendFailure.rejected => l.rejectedTitle,
      SendFailure.blocked => l.failedConnectionLost,
      SendFailure.pinRequired => l.pinEnterTitle,
      _ => l.failedConnectionLost,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScreenHeader(title: l.failedTitle, onBack: onBack),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: p.primary),
              const SizedBox(height: AppSpacing.lg),
              Text(message,
                  style: AppText.body.copyWith(color: p.ink),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: PrimaryButton(label: l.actionRetry, onPressed: onRetry),
        ),
      ],
    );
  }
}
