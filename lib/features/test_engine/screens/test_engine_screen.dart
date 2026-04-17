import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/domain/entities/test_question.dart';
import '../../../core/domain/errors/app_errors.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/extensions/context_extensions.dart';
import '../../../shared/widgets/top_snack_bar.dart';
import '../../history/widgets/explanation_card.dart';
import '../providers/test_session_provider.dart';
import '../providers/test_session_state.dart';

class TestEngineScreen extends HookConsumerWidget {
  const TestEngineScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(testSessionProvider(sessionId).notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: Text('Leave test?', style: AppTextStyles.h3()),
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
      },
      child: Scaffold(
        body: SafeArea(child: _TestEngineAsyncBody(sessionId: sessionId)),
      ),
    );
  }
}

class _TestEngineAsyncBody extends HookConsumerWidget {
  const _TestEngineAsyncBody({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(
      testSessionProvider(sessionId).select((a) => a.isLoading),
    );
    final err = ref.watch(
      testSessionProvider(sessionId).select((a) => a.hasError ? a.error : null),
    );
    final notifier = ref.read(testSessionProvider(sessionId).notifier);

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (err != null) {
      final isNotFound = err is SessionNotFoundException;
      final isNoQuestions = err is SessionHasNoQuestionsException;
      final msg =
          isNotFound
              ? 'Session not found'
              : isNoQuestions
              ? 'Something went wrong'
              : 'Could not load test session.';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(msg, style: AppTextStyles.body()),
              const SizedBox(height: AppSpacing.lg),
              if (!isNotFound && !isNoQuestions)
                OutlinedButton(
                  onPressed: notifier.reload,
                  child: Text('Retry', style: AppTextStyles.label()),
                ),
              if (isNotFound || isNoQuestions) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => context.go('/'),
                  child: Text('Home', style: AppTextStyles.label()),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return _TestEngineLoaded(sessionId: sessionId);
  }
}

class _TestEngineTimerTicker extends HookConsumerWidget {
  const _TestEngineTimerTicker({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run = ref.watch(
      testSessionProvider(sessionId).select((a) {
        final v = a.asData?.value;
        if (v?.session == null) return false;
        if (v!.explanationVisible && v.session!.mode == 'learning') {
          return false;
        }
        return true;
      }),
    );

    useEffect(() {
      if (!run) return null;
      Timer? timer;
      timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        final notifier = ref.read(testSessionProvider(sessionId).notifier);
        notifier.tickSecond();
        final now = ref.read(testSessionProvider(sessionId)).asData?.value;
        final current = now?.session;
        if (now == null || current == null) return;

        if (current.mode == 'learning') {
          if (!now.explanationVisible && now.learningRemainingSecs <= 0) {
            await notifier.onLearningTimedOut();
          }
        } else if (current.isTimed && current.timeLimitSecs != null) {
          final remain = current.timeLimitSecs! - now.totalElapsedSecs;
          if (remain <= 0 && !now.isSubmitting) {
            try {
              final submitted = await notifier.submit();
              if (context.mounted) context.go('/results/$submitted');
            } catch (_) {}
          }
        }
      });
      return () => timer?.cancel();
    }, [run, sessionId]);

    return const SizedBox.shrink();
  }
}

class _TestEngineLoaded extends HookConsumerWidget {
  const _TestEngineLoaded({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(testSessionProvider(sessionId).notifier);
    final sessionLanguage = ref.watch(
          testSessionProvider(
            sessionId,
          ).select((a) => a.asData?.value.session?.language),
        ) ??
        'en';
    final uiLanguage = useState(sessionLanguage);
    final showBanner = ref.watch(
      testSessionProvider(
        sessionId,
      ).select((a) => a.asData?.value.showTimedExamResumeBanner ?? false),
    );

    return Column(
      children: [
        _TestEngineTimerTicker(sessionId: sessionId),
        if (showBanner)
          Material(
            color: AppColors.transparent,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Text(
                'Timer paused while app was closed. Remaining time may not be accurate.',
                style: AppTextStyles.caption().copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        _TopBar(
          sessionId: sessionId,
          uiLanguage: uiLanguage.value,
          onLanguageChanged: (value) => uiLanguage.value = value,
        ),
        _ExamActionRow(
          sessionId: sessionId,
          onPalette: () => _showTestPaletteSheet(context, ref, sessionId),
          onSubmit: () => _showTestPaletteSheet(context, ref, sessionId),
        ),
        Expanded(
          child: _QuestionArea(
            sessionId: sessionId,
            uiLanguage: uiLanguage.value,
            onSelectOption: notifier.selectOption,
          ),
        ),
        _BottomBar(
          sessionId: sessionId,
          onPrev: notifier.movePrev,
          onNext: notifier.moveNext,
          onBookmark: () async {
            final marked = await notifier.toggleBookmark();
            if (!context.mounted) return;
            showTopSnackBar(
              context,
              content: Text(
                marked ? 'Bookmarked' : 'Bookmark removed',
                style: AppTextStyles.bodyMd().copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          },
          onSubmitLearning: () async {
            try {
              final id = await notifier.submit();
              if (context.mounted) context.go('/results/$id');
            } catch (_) {}
          },
        ),
      ],
    );
  }
}

Future<void> _showTestPaletteSheet(
  BuildContext context,
  WidgetRef ref,
  String sessionId,
) async {
  final async = ref.read(testSessionProvider(sessionId));
  final state = async.asData?.value;
  final notifier = ref.read(testSessionProvider(sessionId).notifier);
  if (state == null || state.session == null) return;
  final session = state.session!;
  if (session.mode != 'exam') return;
  final attempted =
      session.questions.where((q) => q.status != 'unattempted').length;
  final flagged = session.questions.where((q) => q.flagged).length;
  final skipped =
      session.questions.where((q) => q.status == 'unattempted').length;
  final isDark = context.isDarkMode;
  final scheme = Theme.of(context).colorScheme;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.transparent,
    builder: (ctx) {
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
              color: AppColors.gray900.withValues(alpha: isDark ? 0.45 : 0.14),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Question Grid',
                style: AppTextStyles.h3().copyWith(
                  color: scheme.onSurface,
                ),
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
                _LegendItem(
                  label: 'Current',
                  bg: AppColors.primary,
                  fg: AppColors.onPrimary,
                ),
                _LegendItem(
                  label: 'Attempted',
                  bg: isDark ? AppColors.correctBgDark : AppColors.correctBg,
                  fg: isDark ? AppColors.correctTextDark : AppColors.correctText,
                ),
                _LegendItem(
                  label: 'Flagged',
                  bg: isDark ? AppColors.warningBgDark : AppColors.warningBg,
                  fg: isDark ? AppColors.warningTextDark : AppColors.warningText,
                ),
                _LegendItem(
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
                for (var i = 0; i < session.questions.length; i++)
                  GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      notifier.jumpToIndex(i);
                    },
                    child: _PaletteCell(
                      index: i,
                      currentIndex: state.currentIndex,
                      q: session.questions[i],
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
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 0.6,
                  ),
                ),
                children: [
                  TableRow(
                    children: [
                      _CountCell(label: 'Attempted', value: '$attempted'),
                      _CountCell(label: 'Skipped', value: '$skipped'),
                      _CountCell(label: 'Flagged', value: '$flagged'),
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
                    onPressed: () async {
                      try {
                        final id = await notifier.submit();
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) context.go('/results/$id');
                      } catch (_) {}
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? scheme.errorContainer : AppColors.wrong,
                      foregroundColor: isDark ? scheme.onErrorContainer : null,
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
}

class _CountCell extends HookConsumerWidget {
  const _CountCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            style: AppTextStyles.caption().copyWith(color: scheme.onSurfaceVariant),
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

class _LegendItem extends HookConsumerWidget {
  const _LegendItem({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TopBar extends HookConsumerWidget {
  const _TopBar({
    required this.sessionId,
    required this.uiLanguage,
    required this.onLanguageChanged,
  });

  final String sessionId;
  final String uiLanguage;
  final ValueChanged<String> onLanguageChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final snap = ref.watch(
      testSessionProvider(sessionId).select((a) {
        final v = a.asData?.value;
        final s = v?.session;
        if (v == null || s == null) return null;
        final i = v.currentIndex;
        if (i < 0 || i >= s.questions.length) return null;
        final q = s.questions[i];
        return (
          v.currentIndex,
          s.questions.length,
          s.mode,
          s.subject,
          s.topic,
          q.flagged,
          v.explanationVisible,
        );
      }),
    );

    if (snap == null) return const SizedBox.shrink();

    final (
      currentIndex,
      qLen,
      mode,
      subject,
      topic,
      flagged,
      explanationVisible,
    ) = snap;

    final subj =
        subject == 'revision'
            ? 'Revision'
            : (SubjectConstants.bySlug(subject)?.displayName ??
                subject);
    final contextText = topic == null ? subj : '$subj · $topic';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Q${currentIndex + 1} of $qLen',
                  style: AppTextStyles.label().copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  contextText,
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ToggleButtons(
            isSelected: [uiLanguage == 'en', uiLanguage == 'hi'],
            onPressed: (index) => onLanguageChanged(index == 0 ? 'en' : 'hi'),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            constraints: const BoxConstraints(minHeight: 28, minWidth: 40),
            children: const [
              Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('EN')),
              Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('HI')),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          if (!(mode == 'learning' && explanationVisible))
            InkWell(
              onTap:
                  () =>
                      ref
                          .read(testSessionProvider(sessionId).notifier)
                          .toggleFlag(),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color:
                      flagged
                          ? (context.isDarkMode
                              ? AppColors.warningBgDark
                              : AppColors.warningBg)
                          : AppColors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  flagged ? Icons.flag : Icons.outlined_flag,
                  size: 18,
                  color: flagged ? AppColors.warning : scheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(width: AppSpacing.sm),
          const _TopBarDarkModeToggle(),
        ],
      ),
    );
  }
}

class _TopBarDarkModeToggle extends HookConsumerWidget {
  const _TopBarDarkModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    return InkWell(
      onTap: () async {
        final prefs = await ref.read(prefsServiceProvider.future);
        prefs.darkModeEnabled = !isDark;
        ref.invalidate(prefsServiceProvider);
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(
          isDark ? Icons.dark_mode : Icons.light_mode,
          size: 18,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _TopBarTimerLabel extends HookConsumerWidget {
  const _TopBarTimerLabel({required this.sessionId});

  final String sessionId;

  static String _mmss(int total) {
    final mm = (total ~/ 60).toString().padLeft(2, '0');
    final ss = (total % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final t = ref.watch(
      testSessionProvider(sessionId).select((a) {
        final v = a.asData?.value;
        final s = v?.session;
        if (v == null || s == null) return null;
        if (s.mode == 'exam') {
          if (s.isTimed && s.timeLimitSecs != null) {
            final remain = (s.timeLimitSecs! - v.totalElapsedSecs).clamp(
              0,
              1 << 30,
            );
            return ('et', remain, remain <= 300);
          }
          return ('eu', v.totalElapsedSecs, false);
        }
        return ('l', v.learningRemainingSecs, false);
      }),
    );

    if (t == null) return const SizedBox.shrink();

    String rightLabel;
    Color rightColor;

    switch (t.$1) {
      case 'et':
        rightLabel = _mmss(t.$2);
        rightColor = t.$3 == true ? AppColors.wrong : scheme.onSurface;
      case 'eu':
        rightLabel = _mmss(t.$2);
        rightColor = scheme.onSurface;
      case 'l':
        final left = t.$2;
        rightLabel = _mmss(left);
        if (left > 30) {
          rightColor = AppColors.correct;
        } else if (left >= 10) {
          rightColor = AppColors.warning;
        } else {
          rightColor = AppColors.wrong;
        }
      default:
        rightLabel = '00:00';
        rightColor = scheme.onSurface;
    }

    return Text(
      rightLabel,
      style: AppTextStyles.label().copyWith(color: rightColor),
    );
  }
}

class _QuestionArea extends HookConsumerWidget {
  const _QuestionArea({
    required this.sessionId,
    required this.uiLanguage,
    required this.onSelectOption,
  });

  final String sessionId;
  final String uiLanguage;
  final Future<void> Function(String option) onSelectOption;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final snap = ref.watch(
      testSessionProvider(sessionId).select((a) {
        final v = a.asData?.value;
        final s = v?.session;
        if (v == null || s == null) return null;
        final i = v.currentIndex;
        if (i < 0 || i >= s.questions.length) return null;
        final q = s.questions[i];
        return (s.mode, v.explanationVisible, v.learningVerdict, q);
      }),
    );

    if (snap == null) return const SizedBox.shrink();

    final (mode, explanationVisible, learningVerdict, question) = snap;
    final isHindi = uiLanguage == 'hi';
    final displayText = isHindi ? question.displayTextHi : question.displayText;
    final optionA = isHindi ? question.optionAHi : question.optionA;
    final optionB = isHindi ? question.optionBHi : question.optionB;
    final optionC = isHindi ? question.optionCHi : question.optionC;
    final optionD = isHindi ? question.optionDHi : question.optionD;
    final tableData = isHindi ? question.tableDataHi : question.tableData;
    final trimmedDisplayText = displayText.trim();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (trimmedDisplayText.isNotEmpty)
            Text(
              trimmedDisplayText,
              style: AppTextStyles.question().copyWith(color: scheme.onSurface),
            ),
          if (question.hasTable && tableData != null) ...[
            SizedBox(
              height: trimmedDisplayText.isNotEmpty
                  ? AppSpacing.sm
                  : AppSpacing.xs,
            ),
            _QuestionTable(table: tableData),
          ],
          const SizedBox(height: AppSpacing.lg),
          _OptionRow(
            keyLabel: 'A',
            optionText: optionA,
            visual: _optionVisual(mode, question, 'a', explanationVisible),
            onTap:
                (mode == 'learning' && explanationVisible)
                    ? null
                    : () => onSelectOption('a'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _OptionRow(
            keyLabel: 'B',
            optionText: optionB,
            visual: _optionVisual(mode, question, 'b', explanationVisible),
            onTap:
                (mode == 'learning' && explanationVisible)
                    ? null
                    : () => onSelectOption('b'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _OptionRow(
            keyLabel: 'C',
            optionText: optionC,
            visual: _optionVisual(mode, question, 'c', explanationVisible),
            onTap:
                (mode == 'learning' && explanationVisible)
                    ? null
                    : () => onSelectOption('c'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _OptionRow(
            keyLabel: 'D',
            optionText: optionD,
            visual: _optionVisual(mode, question, 'd', explanationVisible),
            onTap:
                (mode == 'learning' && explanationVisible)
                    ? null
                    : () => onSelectOption('d'),
          ),
          if (mode == 'learning') ...[
            const SizedBox(height: AppSpacing.lg),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child:
                  explanationVisible
                      ? _ExplanationCard(
                        question: question,
                        uiLanguage: uiLanguage,
                        verdict: learningVerdict,
                      )
                      : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }

  _OptionVisual _optionVisual(
    String mode,
    TestQuestion q,
    String key,
    bool revealed,
  ) {
    final selected = q.selectedOption == key;
    final isCorrect = q.correctOption.toLowerCase() == key;

    if (mode == 'learning' && revealed) {
      if (q.status == 'timed_out') {
        if (isCorrect) return _OptionVisual.correct;
        return _OptionVisual.unselected;
      }
      if (isCorrect) return _OptionVisual.correct;
      if (selected && !isCorrect) return _OptionVisual.wrong;
      return _OptionVisual.unselected;
    }

    if (selected) return _OptionVisual.selected;
    return _OptionVisual.unselected;
  }
}

enum _OptionVisual { unselected, selected, correct, wrong }

class _OptionRow extends HookConsumerWidget {
  const _OptionRow({
    required this.keyLabel,
    required this.optionText,
    required this.visual,
    required this.onTap,
  });

  final String keyLabel;
  final String optionText;
  final _OptionVisual visual;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;

    Color bg;
    Color border;
    Color text;
    Color badgeBg;
    Color badgeText;
    double borderWidth;

    switch (visual) {
      case _OptionVisual.unselected:
        bg = scheme.surface;
        border = isDark ? AppColors.borderDark : AppColors.borderLight;
        text = scheme.onSurface;
        badgeBg = scheme.surfaceContainerLow;
        badgeText = scheme.onSurfaceVariant;
        borderWidth = 0.5;
      case _OptionVisual.selected:
        bg = isDark ? AppColors.primaryDeep : AppColors.primaryLight;
        border = AppColors.primary;
        text = isDark ? AppColors.onPrimary : AppColors.primaryDeep;
        badgeBg = AppColors.primary;
        badgeText = AppColors.onPrimary;
        borderWidth = 2;
      case _OptionVisual.correct:
        bg = isDark ? AppColors.correctBgDark : AppColors.correctBg;
        border = AppColors.correct;
        text = isDark ? AppColors.correctTextDark : AppColors.correctText;
        badgeBg = AppColors.correct;
        badgeText = AppColors.onPrimary;
        borderWidth = 2;
      case _OptionVisual.wrong:
        bg = isDark ? AppColors.wrongBgDark : AppColors.wrongBg;
        border = AppColors.wrong;
        text = isDark ? AppColors.wrongTextDark : AppColors.wrongText;
        badgeBg = AppColors.wrong;
        badgeText = AppColors.onPrimary;
        borderWidth = 2;
    }

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: border, width: borderWidth),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
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
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  optionText,
                  style: AppTextStyles.option().copyWith(color: text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionTable extends HookConsumerWidget {
  const _QuestionTable({required this.table});

  final QuestionTableData table;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final header = table.header?.trim();
    final footer = table.footer?.trim();
    final columnCount = table.columns.length;

    if (columnCount == 0) return const SizedBox.shrink();

    final allRows = <List<String>>[
      table.columns,
      ...table.rows.map((row) {
        if (row.length == columnCount) return row;
        if (row.length < columnCount) {
          return [...row, ...List.filled(columnCount - row.length, '')];
        }
        return row.take(columnCount).toList();
      }),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null && header.isNotEmpty) ...[
          Text(
            header,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: border, width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder.all(color: border, width: 0.5),
              columnWidths: {
                for (var i = 0; i < columnCount; i++)
                  i: const FlexColumnWidth(),
              },
              children: [
                for (var rowIndex = 0; rowIndex < allRows.length; rowIndex++)
                  TableRow(
                    decoration: BoxDecoration(
                      color: rowIndex == 0
                          ? scheme.surfaceContainerLow
                          : scheme.surface,
                    ),
                    children: [
                      for (final cell in allRows[rowIndex])
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.sm,
                          ),
                          child: Text(
                            cell,
                            textAlign: TextAlign.left,
                            style: (rowIndex == 0
                                    ? AppTextStyles.labelSm()
                                    : AppTextStyles.bodySm())
                                .copyWith(color: scheme.onSurface),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (footer != null && footer.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            footer,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _ExplanationCard extends HookConsumerWidget {
  const _ExplanationCard({
    required this.question,
    required this.uiLanguage,
    required this.verdict,
  });

  final TestQuestion question;
  final String uiLanguage;
  final LearningVerdict? verdict;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        "Time's up",
      ),
    };

    return Container(
      key: ValueKey('${question.uuid}-${verdict?.name ?? 'none'}'),
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
                child: Text(
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
            'Why',
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

class _BottomBar extends HookConsumerWidget {
  const _BottomBar({
    required this.sessionId,
    required this.onPrev,
    required this.onNext,
    required this.onBookmark,
    required this.onSubmitLearning,
  });

  final String sessionId;
  final Future<void> Function() onPrev;
  final Future<void> Function() onNext;
  final Future<void> Function() onBookmark;
  final Future<void> Function() onSubmitLearning;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(
      testSessionProvider(sessionId).select((a) {
        final v = a.asData?.value;
        final s = v?.session;
        if (v == null || s == null) return null;
        return (
          s.mode,
          v.currentIndex,
          s.questions.length,
          v.furthestAnsweredIndex,
          v.bookmarkedByUuid[s.questions[v.currentIndex].uuid] ?? false,
          s.questions[v.currentIndex].selectedOption != null ||
              s.questions[v.currentIndex].status == 'timed_out',
        );
      }),
    );

    if (snap == null) return const SizedBox.shrink();

    final (
      mode,
      currentIndex,
      qLen,
      furthestAnsweredIndex,
      currentBookmarked,
      currentQuestionAnswered,
    ) = snap;
    final last = currentIndex == qLen - 1;
    final canPrev = currentIndex > 0;
    final canAdvanceLearning =
        currentIndex < furthestAnsweredIndex || currentQuestionAnswered;
    final canNext = mode == 'exam' ? !last : (!last && canAdvanceLearning);
    final canSubmitLearning =
        mode == 'learning' && last && currentQuestionAnswered;

    return Container(
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
              onPressed: canPrev ? onPrev : null,
              icon: const Icon(Icons.chevron_left, size: 18),
              label: const Text('Prev'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: onBookmark,
            icon: Icon(
              currentBookmarked ? Icons.bookmark : Icons.bookmark_border,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child:
                mode == 'learning' && last
                    ? ElevatedButton(
                      onPressed: canSubmitLearning ? onSubmitLearning : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Submit'),
                    )
                    : OutlinedButton.icon(
                      onPressed: canNext ? onNext : null,
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.chevron_right, size: 18),
                      label: const Text('Next'),
                    ),
          ),
        ],
      ),
    );
  }
}

class _ExamActionRow extends HookConsumerWidget {
  const _ExamActionRow({
    required this.sessionId,
    required this.onPalette,
    required this.onSubmit,
  });

  final String sessionId;
  final Future<void> Function() onPalette;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    final mode = ref.watch(
      testSessionProvider(
        sessionId,
      ).select((a) => a.asData?.value.session?.mode ?? 'exam'),
    );
    if (mode != 'exam') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: onPalette,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
            child: const Icon(Icons.grid_view_outlined, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          _TopBarTimerLabel(sessionId: sessionId),
          const Spacer(),
          ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? scheme.errorContainer : AppColors.wrong,
              foregroundColor: isDark ? scheme.onErrorContainer : null,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _PaletteCell extends HookConsumerWidget {
  const _PaletteCell({
    required this.index,
    required this.currentIndex,
    required this.q,
    required this.isDark,
  });

  final int index;
  final int currentIndex;
  final TestQuestion q;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color bg;
    Color fg;

    if (index == currentIndex) {
      bg = AppColors.primary;
      fg = AppColors.onPrimary;
    } else if (q.flagged) {
      bg = isDark ? AppColors.warningBgDark : AppColors.warningBg;
      fg = isDark ? AppColors.warningTextDark : AppColors.warningText;
    } else if (q.status != 'unattempted') {
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
