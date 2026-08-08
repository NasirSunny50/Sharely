import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sharely/core/logger.dart';
import 'package:sharely/design/app_palette.dart';
import 'package:sharely/design/components.dart';
import 'package:sharely/design/tokens.dart';
import 'package:sharely/l10n/generated/app_localizations.dart';

/// A local, user-clearable log viewer (§2.3 — the only "telemetry" is this
/// on-device ring buffer). Newest first, copy-all and clear actions.
class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final entries = SharelyLogger.instance.entries.reversed.toList();

    Color colorFor(LogLevel level) => switch (level) {
          LogLevel.error => p.primary,
          LogLevel.warn => p.favText,
          LogLevel.info => p.inkSecondary,
          LogLevel.debug => p.mutedLight,
        };

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            title: l.logTitle,
            onBack: () => context.pop(),
            trailing: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.copy, color: p.muted, size: 20),
                  onPressed: entries.isEmpty
                      ? null
                      : () => Clipboard.setData(ClipboardData(
                            text: SharelyLogger.instance.entries
                                .map((e) => e.toString())
                                .join('\n'),
                          )),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: p.muted, size: 20),
                  onPressed: () => setState(SharelyLogger.instance.clear),
                ),
              ],
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(l.logEmpty,
                        style: AppText.body.copyWith(color: p.muted)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.screenH),
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: RichText(
                          text: TextSpan(
                            style: AppText.dataSmall.copyWith(color: p.ink),
                            children: [
                              TextSpan(
                                text:
                                    '${e.level.name.toUpperCase().padRight(5)} ',
                                style: TextStyle(color: colorFor(e.level)),
                              ),
                              TextSpan(
                                text: '${e.tag}  ',
                                style: TextStyle(color: p.muted),
                              ),
                              TextSpan(text: e.message),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
