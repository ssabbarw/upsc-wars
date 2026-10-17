import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/backup/session_backup_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/data_restore_provider.dart';

/// Temporary Home card shown while a signed-in account's backed-up tests are
/// being restored after a (re)install, so the app never feels stuck.
///
/// Renders nothing when there is nothing to restore. The finished state
/// dismisses itself after a few seconds.
class DataRestoreBanner extends HookConsumerWidget {
  const DataRestoreBanner({super.key});

  static const _doneVisibleFor = Duration(seconds: 6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(dataRestoreProvider);
    final phase = progress.phase;

    useEffect(() {
      if (phase != RestorePhase.done) return null;
      final t = Timer(_doneVisibleFor, () {
        ref.read(dataRestoreProvider.notifier).dismiss();
      });
      return t.cancel;
    }, [phase]);

    final visible =
        (phase == RestorePhase.restoring && progress.total > 0) ||
        phase == RestorePhase.done ||
        phase == RestorePhase.failed;
    if (!visible) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final failed = phase == RestorePhase.failed;
    final done = phase == RestorePhase.done;

    final accent = failed
        ? AppColors.warning
        : (done ? AppColors.primary : AppColors.info);
    final fg = failed
        ? (isDark ? AppColors.warningTextDark : AppColors.warningText)
        : (isDark ? AppColors.infoTextDark : AppColors.infoText);

    final String title;
    final String body;
    if (failed) {
      title = 'Restore paused';
      body = progress.message ?? 'Could not restore your data.';
    } else if (done) {
      title = 'Your data is back';
      body = progress.message ?? 'Restored your tests.';
    } else {
      title = 'Restoring your data…';
      body = '${progress.done} of ${progress.total} tests'
          '${progress.message == null ? '' : ' · ${progress.message}'}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: isDark ? 0.14 : 0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: accent.withValues(alpha: isDark ? 0.55 : 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (failed)
                    Icon(Icons.cloud_off_rounded, size: 20, color: fg)
                  else if (done)
                    Icon(Icons.cloud_done_rounded, size: 20, color: fg)
                  else
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: accent,
                      ),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.label().copyWith(
                            color: fg,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          body,
                          style: AppTextStyles.bodySm().copyWith(
                            color: scheme.onSurface,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (failed) ...[
                    TextButton(
                      onPressed: () => unawaited(
                        ref.read(dataRestoreProvider.notifier).retry(),
                      ),
                      child: const Text('Retry'),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Dismiss',
                      onPressed: () =>
                          ref.read(dataRestoreProvider.notifier).dismiss(),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              if (phase == RestorePhase.restoring) ...[
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: LinearProgressIndicator(
                    value: progress.fraction,
                    minHeight: 5,
                    color: accent,
                    backgroundColor: accent.withValues(alpha: 0.18),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'You can keep using the app while this finishes.',
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
