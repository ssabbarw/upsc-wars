import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/domain/entities/home_state.dart';
import '../../../core/domain/entities/session_config.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/app_bootstrap.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/providers/quick_practice_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/prelims_countdown_card.dart';
import '../../../shared/widgets/quick_practice_mode_sheet.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final home = ref.watch(homeStateProvider);
    final totalQuestions = ref.watch(totalQuestionCountProvider);
    final bootstrap = ref.watch(appBootstrapProvider);
    final cachedStreakText = useState<String?>(null);

    final past200ms = useState(false);
    useEffect(() {
      final t = Timer(const Duration(milliseconds: 200), () {
        past200ms.value = true;
      });
      return t.cancel;
    }, const []);

    useEffect(() {
      Future(() async {
        final uc = await ref.read(updateStreakUseCaseProvider.future);
        await uc.execute();
        ref.invalidate(homeStateProvider);
      });
      return null;
    }, const []);

    useEffect(() {
      home.whenData((h) {
        cachedStreakText.value =
            h.streakCount == 0 ? 'Start your streak' : '${h.streakCount} days';
      });
      return null;
    }, [home]);

    final greeting = _greeting();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final exit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Exit app?', style: AppTextStyles.h3()),
            content: Text(
              'You will leave UPSC Wars.',
              style: AppTextStyles.bodyMd(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        if (exit == true && context.mounted) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (bootstrap.hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Material(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Question bank unavailable',
                            style: AppTextStyles.label().copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'The question database could not be opened. Reinstall the app or ensure storage is available, then restart.',
                            style: AppTextStyles.bodySm().copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: AppTextStyles.h2().copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          'Aspirant',
                          style: AppTextStyles.bodySm().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: AppColors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final prefs = await ref.read(prefsServiceProvider.future);
                        prefs.darkModeEnabled = !isDark;
                        ref.invalidate(prefsServiceProvider);
                      },
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        margin: const EdgeInsets.only(right: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: borderColor, width: 0.5),
                        ),
                        child: Icon(
                          isDark ? Icons.dark_mode : Icons.light_mode,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: borderColor, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: AppColors.streak,
                          size: 16,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          home.when(
                            data: (h) => h.streakCount == 0
                                ? 'Start your streak'
                                : '${h.streakCount} days',
                            loading: () =>
                                cachedStreakText.value ?? 'Start your streak',
                            error: (_, __) =>
                                cachedStreakText.value ?? 'Start your streak',
                          ),
                          style: AppTextStyles.caption().copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const PrelimsCountdownCard(),
              const SizedBox(height: AppSpacing.md),
              Material(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: totalQuestions.when(
                    data: (count) => Text(
                      'Temp debug: Total questions in DB = $count',
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    loading: () => Text(
                      'Temp debug: Reading total questions...',
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    error: (e, _) => Text(
                      'Temp debug: Failed to read question count: $e',
                      style: AppTextStyles.bodySm().copyWith(
                        color: AppColors.wrong,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              home.when(
                loading: () {
                  if (!past200ms.value) {
                    return SizedBox(
                      height: 120,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  }
                  return _HeaderLoading(borderColor: borderColor);
                },
                error: (e, st) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlinedButton(
                      onPressed: () => ref.invalidate(homeStateProvider),
                      child: Text('Retry', style: AppTextStyles.label()),
                    ),
                  ],
                ),
                data: (h) {
                  final goalDone = h.dailyGoalProgress >= h.dailyGoalTarget;
                  final progress = h.dailyGoalTarget == 0
                      ? 0.0
                      : (h.dailyGoalProgress / h.dailyGoalTarget)
                            .clamp(0.0, 1.0)
                            .toDouble();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Today's goal",
                            style: AppTextStyles.labelSm().copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            goalDone
                                ? 'Goal complete!'
                                : '${h.dailyGoalProgress} / ${h.dailyGoalTarget} questions',
                            style: AppTextStyles.caption().copyWith(
                              color: goalDone
                                  ? AppColors.correct
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          color: AppColors.primary,
                          backgroundColor: scheme.surfaceContainerLow,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _PrimaryActionCard(home: h, borderColor: borderColor),
                      const SizedBox(height: AppSpacing.md),
                      _QuickPracticeSection(borderColor: borderColor),
                      const SizedBox(height: AppSpacing.md),
                      _QuickGrid(home: h, borderColor: borderColor),
                      if (h.revisionTrapCount > 0) ...[
                        const SizedBox(height: AppSpacing.md),
                        _TrapPatternsCard(
                          trapCount: h.revisionTrapCount,
                          borderColor: borderColor,
                        ),
                      ],
                      if (h.lastSession != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _LastSessionCard(home: h, borderColor: borderColor),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _HeaderLoading extends HookConsumerWidget {
  const _HeaderLoading({required this.borderColor});
  final Color borderColor;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 0.5),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ],
    );
  }
}

class _PrimaryActionCard extends HookConsumerWidget {
  const _PrimaryActionCard({required this.home, required this.borderColor});
  final HomeState home;
  final Color borderColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final hasRevision = home.revisionQueueCount > 0;

    if (!hasRevision) {
      return Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () => context.push('/subject-test'),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: borderColor, width: 0.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start a test',
                        style: AppTextStyles.h3().copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'No weak areas identified yet',
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.onSurface),
              ],
            ),
          ),
        ),
      );
    }

    // Has revision items — show Weak Areas card with two CTAs
    final loading = useState(false);

    Future<void> practiceNow() async {
      if (loading.value) return;
      loading.value = true;
      try {
        final create = await ref.read(createSessionUseCaseProvider.future);
        final count = home.revisionQueueCount.clamp(1, 50);
        final id = await create.execute(
          SessionConfig(
            subject: 'revision',
            mode: 'learning',
            questionCount: count,
            isTimed: true,
            timeLimitSecs: 60,
            language: 'en',
          ),
        );
        if (context.mounted) context.push('/test/$id');
      } finally {
        loading.value = false;
      }
    }

    final hasSubTopics = home.revisionSubTopicCount > 0;
    final hasTraps = home.revisionTrapCount > 0;
    final summaryParts = [
      if (hasSubTopics)
        '${home.revisionSubTopicCount} ${home.revisionSubTopicCount == 1 ? 'sub-topic' : 'sub-topics'}',
      if (hasTraps)
        '${home.revisionTrapCount} trap ${home.revisionTrapCount == 1 ? 'pattern' : 'patterns'}',
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weak Areas',
            style: AppTextStyles.h3().copyWith(color: AppColors.onPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            summaryParts.isNotEmpty
                ? summaryParts.join(' · ')
                : '${home.revisionQueueCount} questions to review',
            style: AppTextStyles.bodySm().copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: loading.value ? null : practiceNow,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.onPrimary,
                    foregroundColor: AppColors.primary,
                  ),
                  child: loading.value
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Text('Practice Now'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/weak-areas'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onPrimary,
                    side: BorderSide(
                      color: AppColors.onPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickGrid extends HookConsumerWidget {
  const _QuickGrid({required this.home, required this.borderColor});
  final HomeState home;
  final Color borderColor;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = [
      _Q(
        'Subject test',
        '6 subjects',
        Icons.menu_book_outlined,
        AppColors.info,
        '/subject-test',
      ),
      _Q(
        'Topic test',
        'Pick any chapter',
        Icons.topic_outlined,
        AppColors.warning,
        '/topic-test',
      ),
      _Q(
        'Bookmarks',
        '${home.bookmarkCount} saved',
        Icons.bookmark_outline,
        AppColors.wrong,
        '/bookmarks',
      ),
      _Q(
        'History',
        'Past sessions',
        Icons.history,
        AppColors.correct,
        '/history',
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.35,
      children: [
        for (final q in data) _QuickCard(q: q, borderColor: borderColor),
      ],
    );
  }
}

class _QuickCard extends HookConsumerWidget {
  const _QuickCard({required this.q, required this.borderColor});
  final _Q q;
  final Color borderColor;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark
        ? q.color.withValues(alpha: 0.25)
        : q.color.withValues(alpha: 0.15);
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () =>
            q.route == '/history' ? context.go(q.route) : context.push(q.route),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(q.icon, size: 18, color: q.color),
              ),
              const Spacer(),
              Text(
                q.title,
                style: AppTextStyles.label().copyWith(color: scheme.onSurface),
              ),
              Text(
                q.subtitle,
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrapPatternsCard extends StatelessWidget {
  const _TrapPatternsCard({required this.trapCount, required this.borderColor});

  final int trapCount;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () => context.push('/weak-areas/traps'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trap Patterns',
                      style: AppTextStyles.label().copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      "You've been caught by $trapCount trap ${trapCount == 1 ? 'type' : 'types'}",
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _LastSessionCard extends HookConsumerWidget {
  const _LastSessionCard({required this.home, required this.borderColor});
  final HomeState home;
  final Color borderColor;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = home.lastSession;
    final scheme = Theme.of(context).colorScheme;
    if (s == null) return const SizedBox.shrink();
    final subj = SubjectConstants.bySlug(s.subject)?.displayName ?? s.subject;
    final title = s.topic == null ? subj : '$subj · ${s.topic}';
    final inProgress = s.status == 'in_progress';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LAST SESSION',
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label().copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            inProgress
                ? '${s.questionCount}Q · in progress'
                : '${s.questionCount}Q · ${s.accuracy?.toStringAsFixed(1) ?? '—'}% · net ${s.netScore?.toStringAsFixed(1) ?? '—'}',
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: inProgress
                ? ElevatedButton(
                    onPressed: () => context.push('/test/${s.sessionId}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: Text('Resume', style: AppTextStyles.labelSm()),
                  )
                : OutlinedButton(
                    onPressed: () => context.push('/history/${s.sessionId}'),
                    child: Text('Review', style: AppTextStyles.labelSm()),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Q {
  const _Q(this.title, this.subtitle, this.icon, this.color, this.route);
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
}

// ── Quick Practice Section ────────────────────────────────────────────────────

class _QuickPracticeSection extends HookConsumerWidget {
  const _QuickPracticeSection({required this.borderColor});
  final Color borderColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revisionCount = ref.watch(activeRevisionQueueCountProvider);
    final bookmarkCount = ref.watch(bookmarkCountStreamProvider);

    final revN = revisionCount.asData?.value ?? 0;
    final bmN = bookmarkCount.asData?.value ?? 0;

    final showRevision = revN >= 3;
    final showBookmarks = bmN >= 3;

    if (!showRevision && !showBookmarks) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK PRACTICE',
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (showRevision) ...[
          _QuickPracticeCard(
            title: 'Revise Incorrects',
            subtitle: 'Unmastered questions',
            count: revN,
            icon: Icons.replay_outlined,
            color: AppColors.wrong,
            borderColor: borderColor,
            subject: 'revision_quick',
          ),
        ],
        if (showRevision && showBookmarks)
          const SizedBox(height: AppSpacing.sm),
        if (showBookmarks) ...[
          _QuickPracticeCard(
            title: 'Bookmarked Questions',
            subtitle: 'Questions you saved',
            count: bmN,
            icon: Icons.bookmark_outline,
            color: AppColors.info,
            borderColor: borderColor,
            subject: 'bookmarks',
          ),
        ],
      ],
    );
  }
}

class _QuickPracticeCard extends HookConsumerWidget {
  const _QuickPracticeCard({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.subject,
  });

  final String title;
  final String subtitle;
  final int count;
  final IconData icon;
  final Color color;
  final Color borderColor;
  final String subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loading = useState(false);
    final capped = count.clamp(1, 10);
    final btnLabel = count >= 10
        ? 'Start 10-question test'
        : 'Start $capped-question test';
    final iconBg = isDark
        ? color.withValues(alpha: 0.25)
        : color.withValues(alpha: 0.12);

    Future<void> startSession() async {
      if (loading.value) return;
      if (!context.mounted) return;

      final mode = await showQuickPracticeModeSheet(context);
      if (mode == null) return;
      if (!context.mounted) return;

      loading.value = true;
      try {
        final create = await ref.read(createSessionUseCaseProvider.future);
        final isTutor = mode == 'tutor';
        final id = await create.execute(
          SessionConfig(
            subject: subject,
            mode: isTutor ? 'learning' : 'exam',
            questionCount: 10,
            isTimed: true,
            timeLimitSecs: isTutor ? 60 : capped * 72,
            language: 'en',
          ),
        );
        if (context.mounted) context.push('/test/$id');
      } finally {
        loading.value = false;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label().copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$count available',
                  style: AppTextStyles.caption().copyWith(color: color),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          loading.value
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : FilledButton(
                  onPressed: startSession,
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(btnLabel, style: AppTextStyles.caption()),
                ),
        ],
      ),
    );
  }
}
