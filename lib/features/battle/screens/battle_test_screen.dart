import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:upsc_wars/core/analytics/analytics.dart';
import 'package:upsc_wars/core/analytics/analytics_events.dart';
import 'package:upsc_wars/core/analytics/session_analytics_derive.dart';
import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/core/providers/prefs_provider.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/features/battle/battle_submit_navigation.dart';
import 'package:upsc_wars/features/battle/providers/battle_session_provider.dart';
import 'package:upsc_wars/features/battle/widgets/battle_live_scoreboard.dart';
import 'package:upsc_wars/features/history/widgets/explanation_card.dart';
import 'package:upsc_wars/features/test_engine/providers/test_session_state.dart';
import 'package:upsc_wars/shared/extensions/context_extensions.dart';
import 'package:upsc_wars/shared/widgets/question_table_view.dart';
import 'package:upsc_wars/shared/widgets/selectable_copy_search_text.dart';
import 'package:upsc_wars/shared/widgets/top_snack_bar.dart';

class BattleTestScreen extends ConsumerWidget {
  const BattleTestScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(battleSessionProvider(sessionId));

    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.battleSession == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Battle')),
        body: Center(
          child: Text(
            state.errorMessage ?? 'Could not open battle.',
            style: AppTextStyles.body(),
          ),
        ),
      );
    }

    return _BattleTestSessionView(sessionId: sessionId);
  }
}

class _BattleTestSessionView extends HookConsumerWidget {
  const _BattleTestSessionView({required this.sessionId});

  final String sessionId;

  static String _mmss(int total) {
    final mm = (total ~/ 60).toString().padLeft(2, '0');
    final ss = (total % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  static int _remainingSecs(BattleSessionUiState s) {
    final b = s.battleSession;
    if (b == null) return 0;
    final limit = b.baseSession.timeLimitSecs;
    if (limit == null) return 0;
    return (limit - s.totalElapsedSecs).clamp(0, limit);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(battleSessionProvider(sessionId).notifier);
    final autoSubmitDone = useRef(false);
    final featureStartedSent = useRef(false);
    final baseSession = ref.watch(
      battleSessionProvider(sessionId).select((u) => u.battleSession?.baseSession),
    );

    useEffect(() {
      final s = baseSession;
      if (s == null || featureStartedSent.value) return null;
      featureStartedSent.value = true;
      final labels = deriveSessionAnalyticsLabels(
        analyticsFeatureKey: s.analyticsFeatureKey,
        subject: s.subject,
      );
      unawaited(
        Analytics.track(
          ref,
          FeatureStartedEvent(
            featureName: labels.featureName,
            subject: s.subject,
            topic: s.topic,
            difficulty: null,
            source: labels.source,
          ),
        ),
      );
      return null;
    }, [baseSession]);

    useEffect(() {
      Timer? timer;
      timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        notifier.tickSecond();
        final ui = ref.read(battleSessionProvider(sessionId));
        if (!context.mounted || ui.battleSession == null) return;
        if (ui.isSubmitting || ui.waitingForGuestToJoin) return;
        final remain = _remainingSecs(ui);
        if (remain > 0) return;
        if (autoSubmitDone.value) return;
        autoSubmitDone.value = true;
        try {
          await submitBattleWithOptionalSpectate(context, ref, sessionId);
        } catch (_) {
          autoSubmitDone.value = false;
        }
      });
      return () => timer?.cancel();
    }, [sessionId]);

    final state = ref.watch(battleSessionProvider(sessionId));
    final battle = state.battleSession!;
    final session = battle.baseSession;
    final idx = state.currentIndex;
    final q = session.questions[idx];
    final isLast = idx == session.questions.length - 1;
    final selectedForCurrent =
        battle.playerResponsesByQuestion[q.uuid] ?? q.selectedOption;
    final revealed = selectedForCurrent != null || q.status != 'unattempted';
    final uiLanguage = useState(session.language);
    final remain = _remainingSecs(state);
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;

    Future<void> confirmLeave() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text('Leave battle?', style: AppTextStyles.h3()),
              content: Text(
                'Your progress will be saved and you can resume later.',
                style: AppTextStyles.bodyMd(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Leave'),
                ),
              ],
            ),
      );
      if (confirmed == true) {
        await notifier.markAbandoned();
        if (context.mounted) context.go('/');
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: confirmLeave,
          ),
          title: Text(
            '${idx + 1}/${session.questions.length}',
            style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Question grid',
              icon: const Icon(Icons.grid_view_outlined),
              onPressed:
                  () => _showBattleQuestionGrid(
                    context,
                    ref,
                    sessionId,
                  ),
            ),
            IconButton(
              tooltip: 'Dark mode',
              icon: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                size: 20,
              ),
              onPressed: () async {
                final prefs = await ref.read(prefsServiceProvider.future);
                prefs.darkModeEnabled = !isDark;
                ref.invalidate(prefsServiceProvider);
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                child: BattleLiveScoreboard(sessionId: sessionId),
              ),
              if (state.waitingForGuestToJoin)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    0,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.hourglass_top,
                            size: 20,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Waiting for your opponent to join before you can answer.',
                              style: AppTextStyles.bodyMd().copyWith(
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap:
                          state.isSubmitting || state.waitingForGuestToJoin
                              ? null
                              : notifier.toggleFlag,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              q.flagged ? Icons.flag : Icons.outlined_flag,
                              size: 18,
                              color:
                                  q.flagged
                                      ? AppColors.warning
                                      : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Revisit',
                              style: AppTextStyles.caption().copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _mmss(remain),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.label().copyWith(
                          color:
                              remain <= 300
                                  ? AppColors.wrong
                                  : scheme.onSurface,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed:
                          state.isSubmitting || state.waitingForGuestToJoin
                              ? null
                              : () async {
                                  try {
                                    await submitBattleWithOptionalSpectate(
                                      context,
                                      ref,
                                      sessionId,
                                    );
                                  } catch (_) {
                                    if (!context.mounted) return;
                                    showTopSnackBar(
                                      context,
                                      content: Text(
                                        'Could not submit battle. Please retry.',
                                        style: AppTextStyles.bodyMd()
                                            .copyWith(
                                              color: scheme.onSurface,
                                            ),
                                      ),
                                    );
                                  }
                                },
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Question',
                              style: AppTextStyles.caption().copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          ToggleButtons(
                            isSelected: [
                              uiLanguage.value == 'en',
                              uiLanguage.value == 'hi',
                            ],
                            onPressed:
                                (i) =>
                                    uiLanguage.value = i == 0 ? 'en' : 'hi',
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            constraints: const BoxConstraints(
                              minHeight: 28,
                              minWidth: 40,
                            ),
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('EN'),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('HI'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _BattleQuestionBlock(
                        question: q,
                        uiLanguage: uiLanguage.value,
                        revealed: revealed,
                        selectedOption: selectedForCurrent,
                        optionsLocked: state.waitingForGuestToJoin,
                        onSelectOption: notifier.selectOption,
                      ),
                    ],
                  ),
                ),
              ),
              if (state.errorMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Text(
                    state.errorMessage!,
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.wrong,
                    ),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: idx > 0 ? notifier.movePrev : null,
                        icon: const Icon(Icons.chevron_left, size: 18),
                        label: const Text('Prev'),
                      ),
                    ),
                    IconButton(
                      onPressed:
                          state.isSubmitting
                              ? null
                              : () async {
                                  final marked = await notifier.toggleBookmark();
                                  if (!context.mounted) return;
                                  showTopSnackBar(
                                    context,
                                    content: Text(
                                      marked
                                          ? 'Bookmarked'
                                          : 'Bookmark removed',
                                      style: AppTextStyles.bodyMd().copyWith(
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                  );
                                },
                      icon: Icon(
                        (state.bookmarkedByUuid[q.uuid] ?? false)
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        size: 22,
                      ),
                    ),
                    Expanded(
                      child:
                          isLast
                              ? ElevatedButton(
                                onPressed:
                                    state.isSubmitting
                                        ? null
                                        : () async {
                                          try {
                                            await submitBattleWithOptionalSpectate(
                                              context,
                                              ref,
                                              sessionId,
                                            );
                                          } catch (_) {
                                            if (!context.mounted) return;
                                            showTopSnackBar(
                                              context,
                                              content: Text(
                                                'Could not submit battle. Please retry.',
                                                style: AppTextStyles.bodyMd()
                                                    .copyWith(
                                                      color: scheme.onSurface,
                                                    ),
                                              ),
                                            );
                                          }
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                ),
                                child: const Text('Submit'),
                              )
                              : OutlinedButton.icon(
                                onPressed: notifier.moveNext,
                                iconAlignment: IconAlignment.end,
                                icon: const Icon(Icons.chevron_right, size: 18),
                                label: const Text('Next'),
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showBattleQuestionGrid(
  BuildContext context,
  WidgetRef ref,
  String sessionId,
) async {
  final asyncState = ref.read(battleSessionProvider(sessionId));
  final battle = asyncState.battleSession;
  if (battle == null) return;
  final notifier = ref.read(battleSessionProvider(sessionId).notifier);
  final isDark = context.isDarkMode;
  final scheme = Theme.of(context).colorScheme;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.transparent,
    builder: (ctx) {
      return Consumer(
        builder: (context, ref2, _) {
          final state = ref2.watch(battleSessionProvider(sessionId));
          final b = state.battleSession;
          if (b == null) {
            return const SizedBox.shrink();
          }
          final session = b.baseSession;
          final questions = session.questions;
          final responses = b.playerResponsesByQuestion;
          final attempted = questions.where((q) {
            return responses.containsKey(q.uuid) ||
                q.status != 'unattempted';
          }).length;
          final skipped = questions.where((q) {
            return !responses.containsKey(q.uuid) &&
                q.status == 'unattempted';
          }).length;
          final flagged = questions.where((q) => q.flagged).length;

          return Container(
            decoration: BoxDecoration(
              color: isDark ? scheme.surfaceContainerHigh : scheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gray900.withValues(
                    alpha: isDark ? 0.45 : 0.14,
                  ),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Question Grid',
                    style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tap any number to jump to that question',
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _BattleGridLegendItem(
                      label: 'Current',
                      bg: AppColors.primary,
                      fg: AppColors.onPrimary,
                    ),
                    _BattleGridLegendItem(
                      label: 'Attempted',
                      bg: isDark ? AppColors.correctBgDark : AppColors.correctBg,
                      fg: isDark
                          ? AppColors.correctTextDark
                          : AppColors.correctText,
                    ),
                    _BattleGridLegendItem(
                      label: 'Flagged',
                      bg: isDark ? AppColors.warningBgDark : AppColors.warningBg,
                      fg: isDark
                          ? AppColors.warningTextDark
                          : AppColors.warningText,
                    ),
                    _BattleGridLegendItem(
                      label: 'Not visited',
                      bg: scheme.surfaceContainerLow,
                      fg: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (var i = 0; i < questions.length; i++)
                      GestureDetector(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          notifier.jumpToIndex(i);
                        },
                        child: _BattlePaletteCell(
                          index: i,
                          currentIndex: state.currentIndex,
                          question: questions[i],
                          answered: responses.containsKey(questions[i].uuid),
                          flagged: questions[i].flagged,
                          isDark: isDark,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 0.6,
                    ),
                  ),
                  child: Table(
                    border: TableBorder.symmetric(
                      inside: BorderSide(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                        width: 0.6,
                      ),
                    ),
                    children: [
                      TableRow(
                        children: [
                          _BattleGridCountCell(
                            label: 'Attempted',
                            value: '$attempted',
                          ),
                          _BattleGridCountCell(
                            label: 'Skipped',
                            value: '$skipped',
                          ),
                          _BattleGridCountCell(
                            label: 'Flagged',
                            value: '$flagged',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Go back'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            state.isSubmitting
                                ? null
                                : () async {
                                  try {
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    await submitBattleWithOptionalSpectate(
                                      context,
                                      ref,
                                      sessionId,
                                    );
                                  } catch (_) {
                                    if (!context.mounted) return;
                                    showTopSnackBar(
                                      context,
                                      content: Text(
                                        'Could not submit battle. Please retry.',
                                        style: AppTextStyles.bodyMd()
                                            .copyWith(
                                              color: scheme.onSurface,
                                            ),
                                      ),
                                    );
                                  }
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark ? scheme.errorContainer : AppColors.wrong,
                          foregroundColor:
                              isDark ? scheme.onErrorContainer : null,
                        ),
                        child: const Text('Submit Test'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _BattleGridLegendItem extends StatelessWidget {
  const _BattleGridLegendItem({
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              '•',
              style: AppTextStyles.caption().copyWith(color: fg, height: 1),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _BattleGridCountCell extends StatelessWidget {
  const _BattleGridCountCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.label().copyWith(color: scheme.onSurface),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BattlePaletteCell extends StatelessWidget {
  const _BattlePaletteCell({
    required this.index,
    required this.currentIndex,
    required this.question,
    required this.answered,
    required this.flagged,
    required this.isDark,
  });

  final int index;
  final int currentIndex;
  final TestQuestion question;
  final bool answered;
  final bool flagged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    if (index == currentIndex) {
      bg = AppColors.primary;
      fg = AppColors.onPrimary;
    } else if (flagged) {
      bg = isDark ? AppColors.warningBgDark : AppColors.warningBg;
      fg = isDark ? AppColors.warningTextDark : AppColors.warningText;
    } else if (answered || question.status != 'unattempted') {
      bg = isDark ? AppColors.correctBgDark : AppColors.correctBg;
      fg = isDark ? AppColors.correctTextDark : AppColors.correctText;
    } else {
      bg = Theme.of(context).colorScheme.surfaceContainerLow;
      fg = Theme.of(context).colorScheme.onSurfaceVariant;
    }

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        '${index + 1}',
        style: AppTextStyles.labelSm().copyWith(color: fg),
      ),
    );
  }
}

class _BattleQuestionBlock extends StatelessWidget {
  const _BattleQuestionBlock({
    required this.question,
    required this.uiLanguage,
    required this.revealed,
    required this.selectedOption,
    required this.onSelectOption,
    this.optionsLocked = false,
  });

  final TestQuestion question;
  final String uiLanguage;
  final bool revealed;
  final String? selectedOption;
  final bool optionsLocked;
  final Future<void> Function(String option) onSelectOption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isHindi = uiLanguage == 'hi';
    final displayText = isHindi ? question.displayTextHi : question.displayText;
    final optionA = isHindi ? question.optionAHi : question.optionA;
    final optionB = isHindi ? question.optionBHi : question.optionB;
    final optionC = isHindi ? question.optionCHi : question.optionC;
    final optionD = isHindi ? question.optionDHi : question.optionD;
    final tableData = isHindi ? question.tableDataHi : question.tableData;
    final trimmed = displayText.trim();

    LearningVerdict? verdict;
    if (revealed) {
      verdict =
          question.status == 'correct'
              ? LearningVerdict.correct
              : LearningVerdict.incorrect;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (trimmed.isNotEmpty)
          SelectableCopySearchText(
            trimmed,
            style: AppTextStyles.question().copyWith(color: scheme.onSurface),
          ),
        if (question.hasTable && tableData != null) ...[
          SizedBox(
            height: trimmed.isNotEmpty ? AppSpacing.sm : AppSpacing.xs,
          ),
          QuestionTableView(table: tableData),
        ],
        const SizedBox(height: AppSpacing.lg),
        for (final opt in const ['a', 'b', 'c', 'd']) ...[
          _BattleOptionRow(
            keyLabel: opt.toUpperCase(),
            optionText: _optText(opt, optionA, optionB, optionC, optionD),
            visual: _battleOptionVisual(
              question,
              opt,
              revealed,
            ),
            onTap:
                revealed || optionsLocked
                    ? null
                    : () => onSelectOption(opt),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (revealed) ...[
          const SizedBox(height: AppSpacing.md),
          _BattleExplanationPanel(
            question: question,
            uiLanguage: uiLanguage,
            verdict: verdict,
          ),
        ],
      ],
    );
  }

  String _optText(
    String opt,
    String a,
    String b,
    String c,
    String d,
  ) {
    switch (opt) {
      case 'a':
        return a;
      case 'b':
        return b;
      case 'c':
        return c;
      default:
        return d;
    }
  }
}

enum _BattleOptionVisual { unselected, selected, correct, wrong }

_BattleOptionVisual _battleOptionVisual(
  TestQuestion q,
  String key,
  bool revealed,
) {
  final selected = q.selectedOption == key;
  final isCorrect = q.correctOption.toLowerCase() == key;

  if (revealed) {
    if (isCorrect) return _BattleOptionVisual.correct;
    if (selected && !isCorrect) return _BattleOptionVisual.wrong;
    return _BattleOptionVisual.unselected;
  }

  if (selected) return _BattleOptionVisual.selected;
  return _BattleOptionVisual.unselected;
}

class _BattleOptionRow extends StatelessWidget {
  const _BattleOptionRow({
    required this.keyLabel,
    required this.optionText,
    required this.visual,
    required this.onTap,
  });

  final String keyLabel;
  final String optionText;
  final _BattleOptionVisual visual;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;

    Color bg;
    Color border;
    Color text;
    Color badgeBg;
    Color badgeText;
    double borderWidth;

    switch (visual) {
      case _BattleOptionVisual.unselected:
        bg = scheme.surface;
        border = isDark ? AppColors.borderDark : AppColors.borderLight;
        text = scheme.onSurface;
        badgeBg = scheme.surfaceContainerLow;
        badgeText = scheme.onSurfaceVariant;
        borderWidth = 0.5;
      case _BattleOptionVisual.selected:
        bg = isDark ? AppColors.primaryDeep : AppColors.primaryLight;
        border = AppColors.primary;
        text = isDark ? AppColors.onPrimary : AppColors.primaryDeep;
        badgeBg = AppColors.primary;
        badgeText = AppColors.onPrimary;
        borderWidth = 2;
      case _BattleOptionVisual.correct:
        bg = isDark ? AppColors.correctBgDark : AppColors.correctBg;
        border = AppColors.correct;
        text = isDark ? AppColors.correctTextDark : AppColors.correctText;
        badgeBg = AppColors.correct;
        badgeText = AppColors.onPrimary;
        borderWidth = 2;
      case _BattleOptionVisual.wrong:
        bg = isDark ? AppColors.wrongBgDark : AppColors.wrongBg;
        border = AppColors.wrong;
        text = isDark ? AppColors.wrongTextDark : AppColors.wrongText;
        badgeBg = AppColors.wrong;
        badgeText = AppColors.onPrimary;
        borderWidth = 2;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: border, width: borderWidth),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onTap != null)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          keyLabel,
                          style: AppTextStyles.labelSm().copyWith(
                            color: badgeText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      keyLabel,
                      style: AppTextStyles.labelSm().copyWith(color: badgeText),
                    ),
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SelectableCopySearchText(
                optionText,
                style: AppTextStyles.option().copyWith(color: text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleExplanationPanel extends StatelessWidget {
  const _BattleExplanationPanel({
    required this.question,
    required this.uiLanguage,
    required this.verdict,
  });

  final TestQuestion question;
  final String uiLanguage;
  final LearningVerdict? verdict;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    final isHindi = uiLanguage == 'hi';
    final finalExplanation = isHindi
        ? question.finalExplanationHi
        : question.finalExplanation;
    final statementAnalysis = isHindi
        ? question.statementAnalysisHi
        : question.statementAnalysis;
    final eliminationLogic = isHindi
        ? question.eliminationLogicHi
        : question.eliminationLogic;
    final strongDistractor = isHindi
        ? question.strongDistractorHi
        : question.strongDistractor;
    final upscTrapExplanation = isHindi
        ? question.upscTrapExplanationHi
        : question.upscTrapExplanation;

    final (badgeBg, badgeText, label) = switch (verdict) {
      LearningVerdict.correct => (
        isDark ? AppColors.correctBgDark : AppColors.correctBg,
        isDark ? AppColors.correctTextDark : AppColors.correctText,
        'Correct',
      ),
      LearningVerdict.incorrect => (
        isDark ? AppColors.wrongBgDark : AppColors.wrongBg,
        isDark ? AppColors.wrongTextDark : AppColors.wrongText,
        'Incorrect',
      ),
      _ => (
        isDark ? AppColors.warningBgDark : AppColors.warningBg,
        isDark ? AppColors.warningTextDark : AppColors.warningText,
        'Answer',
      ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.caption().copyWith(color: badgeText),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SelectableCopySearchText(
                  question.conceptAnchor ?? '',
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Explanation',
            style: AppTextStyles.label().copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          ExplanationCard(
            translation: QuestionTranslation(
              finalExplanation: finalExplanation,
              statementAnalysis:
                  statementAnalysis
                      .map(
                        (e) => StatementAnalysisVm(
                          statement: e.label,
                          isCorrect: e.isCorrect,
                          reason: e.reason,
                        ),
                      )
                      .toList(),
              eliminationLogic: eliminationLogic,
              strongDistractor: strongDistractor,
              upscTrapExplanation: upscTrapExplanation,
              conceptsUsed: question.conceptsUsed,
            ),
            showStatements: statementAnalysis.isNotEmpty,
          ),
        ],
      ),
    );
  }
}
