import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sharely/core/format.dart';
import 'package:sharely/design/app_palette.dart';
import 'package:sharely/design/components.dart';
import 'package:sharely/design/tokens.dart';
import 'package:sharely/features/history/history_store.dart';
import 'package:sharely/l10n/generated/app_localizations.dart';

/// Screens 27/28 — transfer history, grouped by day, backed by Hive.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final store = ref.watch(historyStoreProvider);

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            title: l.historyTitle,
            onBack: () => context.pop(),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: p.muted),
              onPressed: store.clear,
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: store.changes,
              builder: (context, _) {
                final records = store.all();
                if (records.isEmpty) return const _Empty();
                final groups = _groupByDay(records);
                return ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenH),
                  children: [
                    for (final entry in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, AppSpacing.lg,
                            0, AppSpacing.sm),
                        child: Text(entry.key.toUpperCase(),
                            style: AppText.badge.copyWith(color: p.mutedLight)),
                      ),
                      for (final r in entry.value) _HistoryRow(record: r),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<TransferRecord>> _groupByDay(List<TransferRecord> records) {
    final now = DateTime.now();
    final groups = <String, List<TransferRecord>>{};
    for (final r in records) {
      final days = DateTime(now.year, now.month, now.day)
          .difference(DateTime(r.at.year, r.at.month, r.at.day))
          .inDays;
      final label = switch (days) {
        0 => 'Today',
        1 => 'Yesterday',
        _ => '${r.at.day}/${r.at.month}/${r.at.year}',
      };
      groups.putIfAbsent(label, () => []).add(r);
    }
    return groups;
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.record});
  final TransferRecord record;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final sent = record.direction == HistoryDirection.sent;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: p.cardSunken,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(sent ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 18, color: p.inkSecondary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${sent ? l.historySent : l.historyReceived} · ${record.deviceName}',
                    style: AppText.bodyLarge.copyWith(color: p.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  DataText(
                    '${record.fileCount} · ${Format.bytes(record.totalBytes)}',
                    style: AppText.dataSmall,
                  ),
                ],
              ),
            ),
            Icon(
              record.success ? Icons.check_circle : Icons.error_outline,
              size: 18,
              color: record.success ? p.success : p.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

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
            Icon(Icons.history, size: 40, color: p.muted),
            const SizedBox(height: AppSpacing.lg),
            Text(l.historyEmpty,
                style: AppText.heading.copyWith(color: p.ink)),
            const SizedBox(height: AppSpacing.sm),
            Text(l.historyEmptyHint,
                style: AppText.body.copyWith(color: p.muted),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
