import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/daily_revision.dart';
import '../domain/start_daily_drill.dart';
import '../providers/daily_drill_provider.dart';
import 'daily_revision_choice_sheet.dart';
import 'today_loop_card.dart';

/// Afternoon revision queue on home — incorrect MCQs or bookmarked MCQs.
class DailyDrillCard extends HookConsumerWidget {
  const DailyDrillCard({
    super.key,
    this.emphasized = false,
    this.layout = TodayLoopLayout.hero,
  });

  final bool emphasized;
  final TodayLoopLayout layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dailyDrillProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loading = useState(false);
    final loggedShown = useRef(false);

    useEffect(() {
      if (loggedShown.value) return null;
      final state = async.maybeWhen(data: (s) => s, orElse: () => null);
      if (state == null) return null;
      loggedShown.value = true;
      unawaited(Analytics.track(ref, const DailyDrillCardShownEvent()));
      unawaited(
        Analytics.track(
          ref,
          const FeatureViewedEvent(
            featureName: 'daily_drill',
            subject: DailyRevision.sessionSubject,
            source: 'home',
          ),
        ),
      );
      return null;
    }, [async]);

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (state) {
        if (state == null) return const SizedBox.shrink();

        Future<void> startPool({
          required DailyRevisionPool pool,
          required String source,
        }) async {
          if (loading.value) return;
          final uuids = state.uuidsFor(pool);
          if (uuids.isEmpty) return;
          loading.value = true;
          try {
            await startRevisionDrill(
              context: context,
              ref: ref,
              pool: pool,
              uuids: uuids,
              source: source,
              completedToday: state.completedToday,
            );
          } finally {
            loading.value = false;
          }
        }

        Future<void> openChoice({required String source}) async {
          if (loading.value) return;
          loading.value = true;
          try {
            await showDailyRevisionChoiceSheet(
              context: context,
              ref: ref,
              source: source,
            );
          } finally {
            loading.value = false;
          }
        }

        final isHero = layout == TodayLoopLayout.hero;
        final counts = layout == TodayLoopLayout.tile
            ? DailyRevision.countsStacked(
                missed: state.wrongCount,
                saved: state.bookmarkCount,
              )
            : DailyRevision.countsLine(
                missed: state.wrongCount,
                saved: state.bookmarkCount,
              );

        return TodayLoopCard(
          layout: layout,
          eyebrow: 'REVISION QUEUE',
          title: 'Revision queue',
          subtitle: counts,
          cta: state.hasAnyPool ? 'Open' : 'Empty',
          icon: Icons.replay_rounded,
          accent: AppColors.primaryDark,
          background: isDark
              ? AppColors.primaryDeep.withValues(alpha: 0.28)
              : AppColors.primaryLight,
          onTap: isHero
              ? null
              : () => unawaited(openChoice(source: 'card')),
          done: false,
          loading: loading.value,
          showNow: emphasized && isHero,
          actions: isHero
              ? _RevisionDoors(
                  wrongCount: state.wrongCount,
                  bookmarkCount: state.bookmarkCount,
                  hasWrongs: state.hasWrongs,
                  hasBookmarks: state.hasBookmarks,
                  loading: loading.value,
                  accent: AppColors.primaryDark,
                  onIncorrect: () => unawaited(
                    startPool(
                      pool: DailyRevisionPool.missed,
                      source: 'card_incorrect',
                    ),
                  ),
                  onBookmarked: () => unawaited(
                    startPool(
                      pool: DailyRevisionPool.saved,
                      source: 'card_bookmarked',
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _RevisionDoors extends StatelessWidget {
  const _RevisionDoors({
    required this.wrongCount,
    required this.bookmarkCount,
    required this.hasWrongs,
    required this.hasBookmarks,
    required this.loading,
    required this.accent,
    required this.onIncorrect,
    required this.onBookmarked,
  });

  final int wrongCount;
  final int bookmarkCount;
  final bool hasWrongs;
  final bool hasBookmarks;
  final bool loading;
  final Color accent;
  final VoidCallback onIncorrect;
  final VoidCallback onBookmarked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Door(
            label: 'incorrects',
            count: '$wrongCount',
            enabled: hasWrongs && !loading,
            accent: accent,
            onTap: onIncorrect,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _Door(
            label: 'bookmarks',
            count: '$bookmarkCount',
            enabled: hasBookmarks && !loading,
            accent: accent,
            onTap: onBookmarked,
          ),
        ),
      ],
    );
  }
}

class _Door extends StatelessWidget {
  const _Door({
    required this.label,
    required this.count,
    required this.enabled,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String count;
  final bool enabled;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: enabled
          ? accent
          : (isDark
                ? scheme.surface.withValues(alpha: 0.4)
                : scheme.surface),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h2().copyWith(
                  color: enabled
                      ? AppColors.onPrimary
                      : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption().copyWith(
                  color: enabled
                      ? AppColors.onPrimary.withValues(alpha: 0.85)
                      : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
