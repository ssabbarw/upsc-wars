import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/constants/daily_drill_constants.dart';
import '../../../core/layout/system_insets.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/dismissible_modal_sheet.dart';
import '../../../shared/widgets/test_config_bottom_sheet.dart';
import '../domain/daily_revision.dart';
import '../providers/daily_drill_provider.dart';
import '../providers/today_hub_provider.dart';

/// Incorrect and bookmarked MCQ tests, side by side on home.
class RevisionTestCards extends HookConsumerWidget {
  const RevisionTestCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final drill = ref.watch(dailyDrillProvider);
    final opening = useState<DailyRevisionPool?>(null);
    final data = drill.asData?.value;
    final loading = drill.isLoading && data == null;
    final failed = drill.hasError && data == null;

    Future<void> open(DailyRevisionPool pool) async {
      if (opening.value != null) return;
      if (failed) {
        ref.invalidate(dailyDrillProvider);
        return;
      }
      HapticFeedback.selectionClick();
      opening.value = pool;
      try {
        await _openHomeRevisionTest(
          context: context,
          ref: ref,
          pool: pool,
          onPresenting: () {
            if (context.mounted) opening.value = null;
          },
        );
      } finally {
        if (context.mounted) opening.value = null;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.homeRevisionSectionTitle,
          style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _PoolCard(
                  pool: DailyRevisionPool.missed,
                  icon: Icons.close_rounded,
                  accent: AppColors.wrong,
                  title: context.l10n.revisionIncorrectMcqs,
                  count: data?.wrongCount,
                  loading: loading,
                  failed: failed,
                  opening: opening.value == DailyRevisionPool.missed,
                  onTap: () => open(DailyRevisionPool.missed),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _PoolCard(
                  pool: DailyRevisionPool.saved,
                  icon: Icons.bookmark_rounded,
                  accent: AppColors.warning,
                  title: context.l10n.revisionBookmarkedMcqs,
                  count: data?.bookmarkCount,
                  loading: loading,
                  failed: failed,
                  opening: opening.value == DailyRevisionPool.saved,
                  onTap: () => open(DailyRevisionPool.saved),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PoolCard extends StatelessWidget {
  const _PoolCard({
    required this.pool,
    required this.icon,
    required this.accent,
    required this.title,
    required this.count,
    required this.loading,
    required this.failed,
    required this.opening,
    required this.onTap,
  });

  final DailyRevisionPool pool;
  final IconData icon;
  final Color accent;
  final String title;
  final int? count;
  final bool loading;
  final bool failed;
  final bool opening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final l10n = context.l10n;
    final available = count ?? 0;
    final ready = !loading && !failed && available > 0;
    final empty = !loading && !failed && available <= 0;
    final testSize = DailyRevision.randomTestSize(available);

    final String subtitle;
    if (failed) {
      subtitle = l10n.tcWentWrong;
    } else if (loading) {
      subtitle = '';
    } else if (empty) {
      subtitle = pool == DailyRevisionPool.saved
          ? l10n.homeRevisionNoBookmarkedCard
          : l10n.homeRevisionNoIncorrectCard;
    } else {
      subtitle = l10n.homeRevisionCardTest(testSize);
    }

    final iconColor = ready ? accent : scheme.onSurfaceVariant;
    final iconFill = ready
        ? accent.withValues(alpha: isDark ? 0.22 : 0.14)
        : scheme.surfaceContainerLow;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: opening ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: border, width: 0.5),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: AppColors.gray900.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconFill,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  const Spacer(),
                  if (opening)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label().copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (loading)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              else if (ready) ...[
                Text(
                  pool == DailyRevisionPool.saved
                      ? l10n.revisionCountBookmark(available)
                      : l10n.revisionCountIncorrect(available),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.primary,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _openHomeRevisionTest({
  required BuildContext context,
  required WidgetRef ref,
  required DailyRevisionPool pool,
  VoidCallback? onPresenting,
}) async {
  final DailyDrillState? drill;
  try {
    drill = await ref.read(dailyDrillProvider.future);
  } on Object {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.tcWentWrong)));
    return;
  }
  if (!context.mounted) return;
  if (drill == null) {
    onPresenting?.call();
    await _showEmptySheet(context, pool);
    return;
  }
  final state = drill;
  final available = switch (pool) {
    DailyRevisionPool.missed => state.wrongCount,
    DailyRevisionPool.saved => state.bookmarkCount,
  };
  if (available <= 0) {
    onPresenting?.call();
    await _showEmptySheet(context, pool);
    return;
  }

  final n = DailyRevision.randomTestSize(available);
  final db = ref.read(userDatabaseProvider);
  final uuids = switch (pool) {
    DailyRevisionPool.missed => await DailyRevision.queryRandomWrongUuids(
      db,
      limit: n,
    ),
    DailyRevisionPool.saved => await DailyRevision.queryRandomBookmarkUuids(
      db,
      limit: n,
    ),
  };
  if (!context.mounted) return;
  if (uuids.isEmpty) {
    onPresenting?.call();
    await _showEmptySheet(context, pool);
    return;
  }

  final l10n = context.l10n;
  final title = switch (pool) {
    DailyRevisionPool.missed => l10n.revisionIncorrectMcqs,
    DailyRevisionPool.saved => l10n.revisionBookmarkedMcqs,
  };
  final count = uuids.length;
  onPresenting?.call();
  await showTestConfigBottomSheet(
    context: context,
    useRootNavigator: true,
    args: TestConfigSheetArgs(
      subject: DailyRevision.sessionSubject,
      subjectDisplayName: l10n.homeRevisionRandomWillStart(count),
      fixedQuestionSetLabel: title,
      availableQuestionCount: count,
      topicCountWhenSubjectOnly: 1,
      lockedQuestionCount: count,
      specificQuestionUuids: uuids,
      analyticsFeatureKey: DailyDrillConstants.analyticsKey,
      onSessionCreated: (sessionId) async {
        unawaited(
          Analytics.track(
            ref,
            DailyDrillStartedEvent(
              subject: DailyRevision.analyticsSubject(pool),
              source: 'home_revision_card',
              completedToday: state.completedToday,
              pool: switch (pool) {
                DailyRevisionPool.missed => 'missed',
                DailyRevisionPool.saved => 'saved',
              },
            ),
          ),
        );
        if (!context.mounted) return;
        await context.push('/test/$sessionId');
        if (!context.mounted) return;
        ref.invalidate(dailyDrillProvider);
        ref.invalidate(todayHubProvider);
      },
    ),
  );
}

Future<void> _showEmptySheet(BuildContext context, DailyRevisionPool pool) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: AppColors.transparent,
    builder: (ctx) => _RevisionEmptySheet(pool: pool),
  );
}

class _RevisionEmptySheet extends StatelessWidget {
  const _RevisionEmptySheet({required this.pool});

  final DailyRevisionPool pool;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final bookmarked = pool == DailyRevisionPool.saved;
    final accent = bookmarked ? AppColors.warning : AppColors.wrong;
    final title = bookmarked
        ? l10n.revisionBookmarkedMcqs
        : l10n.revisionIncorrectMcqs;
    final message = bookmarked
        ? l10n.homeRevisionNoBookmarked
        : l10n.homeRevisionNoIncorrect;
    final hint = bookmarked
        ? l10n.homeRevisionNoBookmarkedHint
        : l10n.homeRevisionNoIncorrectHint;

    return DismissOnScrimTap(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.sm,
          0,
          AppSpacing.sm,
          sheetBottomPadding(context),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isDark ? 0.22 : 0.14),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        bookmarked
                            ? Icons.bookmark_border_rounded
                            : Icons.close_rounded,
                        color: accent,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h3().copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body().copyWith(
                      color: scheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    hint,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.commonGotIt),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
