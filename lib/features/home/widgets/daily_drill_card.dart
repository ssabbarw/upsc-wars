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

/// Afternoon revision on home — missed questions or bookmarks.
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

        final counts = DailyRevision.countsLine(
          missed: state.wrongCount,
          saved: state.bookmarkCount,
        );
        final isHero = layout == TodayLoopLayout.hero;
        final showDoors = isHero && state.hasAnyPool;

        final String title;
        final String subtitle;
        final String cta;
        if (!state.hasAnyPool) {
          title = layout == TodayLoopLayout.tile
              ? 'Nothing yet'
              : 'The ones that got away';
          subtitle = layout == TodayLoopLayout.tile
              ? 'After you write'
              : 'Misses and bookmarks land here after you write.';
          cta = 'Later';
        } else if (state.completedToday) {
          title = layout == TodayLoopLayout.tile ? counts : 'The ones that got away';
          subtitle = layout == TodayLoopLayout.tile
              ? 'Done'
              : counts;
          cta = isHero ? 'Another set' : 'Done';
        } else {
          title = layout == TodayLoopLayout.tile
              ? counts
              : 'The ones that got away';
          subtitle = layout == TodayLoopLayout.tile
              ? 'Missed or saved'
              : counts;
          cta = isHero ? 'Choose a set' : 'Choose';
        }

        return TodayLoopCard(
          layout: layout,
          eyebrow: 'REVISION',
          title: title,
          subtitle: subtitle,
          cta: cta,
          icon: Icons.replay_rounded,
          accent: AppColors.primaryDark,
          background: isDark
              ? AppColors.primaryDeep.withValues(alpha: 0.28)
              : AppColors.primaryLight,
          onTap: state.hasAnyPool && !showDoors
              ? () => unawaited(openChoice(source: 'card'))
              : null,
          done: state.completedToday,
          loading: loading.value,
          showNow: emphasized && isHero,
          actions: showDoors
              ? _RevisionDoors(
                  wrongCount: state.wrongCount,
                  bookmarkCount: state.bookmarkCount,
                  hasWrongs: state.hasWrongs,
                  hasBookmarks: state.hasBookmarks,
                  loading: loading.value,
                  accent: AppColors.primaryDark,
                  onMissed: () => unawaited(
                    startPool(
                      pool: DailyRevisionPool.missed,
                      source: 'card_missed',
                    ),
                  ),
                  onSaved: () => unawaited(
                    startPool(
                      pool: DailyRevisionPool.saved,
                      source: 'card_saved',
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
    required this.onMissed,
    required this.onSaved,
  });

  final int wrongCount;
  final int bookmarkCount;
  final bool hasWrongs;
  final bool hasBookmarks;
  final bool loading;
  final Color accent;
  final VoidCallback onMissed;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Door(
            label: wrongCount == 1 ? '1 missed' : '$wrongCount missed',
            enabled: hasWrongs && !loading,
            accent: accent,
            onTap: onMissed,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _Door(
            label: bookmarkCount == 1 ? '1 saved' : '$bookmarkCount saved',
            enabled: hasBookmarks && !loading,
            accent: accent,
            onTap: onSaved,
          ),
        ),
      ],
    );
  }
}

class _Door extends StatelessWidget {
  const _Door({
    required this.label,
    required this.enabled,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: enabled ? accent : scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSm().copyWith(
              color: enabled ? AppColors.onPrimary : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
