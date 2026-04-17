import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/domain/entities/home_state.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/app_bootstrap.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

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
                            style: AppTextStyles.label()
                                .copyWith(color: scheme.onSurface),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'The question database could not be opened. Reinstall the app or ensure storage is available, then restart.',
                            style: AppTextStyles.bodySm()
                                .copyWith(color: scheme.onSurfaceVariant),
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
                          style: AppTextStyles.h2()
                              .copyWith(color: scheme.onSurface),
                        ),
                        Text(
                          'Aspirant',
                          style: AppTextStyles.bodySm()
                              .copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
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
                          home.maybeWhen(
                            data: (h) => h.streakCount == 0
                                ? 'Start your streak'
                                : '${h.streakCount} days',
                            orElse: () => 'Start your streak',
                          ),
                          style: AppTextStyles.caption()
                              .copyWith(color: scheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                      style: AppTextStyles.bodySm()
                          .copyWith(color: scheme.onSurface),
                    ),
                    loading: () => Text(
                      'Temp debug: Reading total questions...',
                      style: AppTextStyles.bodySm()
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                    error: (e, _) => Text(
                      'Temp debug: Failed to read question count: $e',
                      style: AppTextStyles.bodySm().copyWith(color: AppColors.wrong),
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
                            style: AppTextStyles.labelSm()
                                .copyWith(color: scheme.onSurface),
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
                      _QuickGrid(home: h, borderColor: borderColor),
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
    final bg = hasRevision ? AppColors.primary : scheme.surfaceContainerLow;
    final fg = hasRevision ? AppColors.onPrimary : scheme.onSurface;
    final sub = hasRevision
        ? AppColors.onPrimary.withValues(alpha: 0.7)
        : scheme.onSurfaceVariant;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap:
            () => context.push(
              hasRevision ? '/revision-queue' : '/subject-test',
            ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: hasRevision
                ? null
                : Border.all(color: borderColor, width: 0.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasRevision ? 'Revision queue' : 'Start a test',
                      style: AppTextStyles.h3().copyWith(color: fg),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      hasRevision
                          ? '${home.revisionQueueCount} questions waiting'
                          : 'No questions in your revision queue',
                      style: AppTextStyles.bodySm().copyWith(color: sub),
                    ),
                    if (hasRevision && home.revisionSubjects.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        home.revisionSubjects
                            .map(
                              (s) =>
                                  SubjectConstants.bySlug(s)?.displayName ?? s,
                            )
                            .join(' · '),
                        style: AppTextStyles.caption().copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: fg),
            ],
          ),
        ),
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
      _Q('Subject test', '6 subjects', Icons.menu_book_outlined,
          AppColors.info, '/subject-test'),
      _Q('Topic test', 'Pick any chapter', Icons.topic_outlined,
          AppColors.warning, '/topic-test'),
      _Q('Bookmarks', '${home.bookmarkCount} saved',
          Icons.bookmark_outline, AppColors.wrong, '/bookmarks'),
      _Q('History', 'Past sessions', Icons.history, AppColors.correct,
          '/history'),
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
    final iconBg =
        isDark ? q.color.withValues(alpha: 0.25) : q.color.withValues(alpha: 0.15);
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap:
            () => q.route == '/history'
                ? context.go(q.route)
                : context.push(q.route),
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
                style: AppTextStyles.caption()
                    .copyWith(color: scheme.onSurfaceVariant),
              ),
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
    final subj =
        SubjectConstants.bySlug(s.subject)?.displayName ?? s.subject;
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
            style: AppTextStyles.caption()
                .copyWith(color: scheme.onSurfaceVariant),
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
            style: AppTextStyles.bodySm()
                .copyWith(color: scheme.onSurfaceVariant),
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
                    onPressed: () =>
                        context.push('/history/${s.sessionId}'),
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
