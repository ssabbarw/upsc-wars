import 'dart:math' show min;

import 'package:flutter/material.dart';

import 'package:upsc_wars/core/domain/entities/answer_confidence.dart';
import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/web_player/web_player_ui_tokens.dart';
import 'package:upsc_wars/shared/extensions/context_extensions.dart';
import 'package:upsc_wars/shared/widgets/selectable_copy_search_text.dart';

/// Mirrors learning-mode option styling from [TestEngineScreen] `_OptionRow`.
enum WebPlayerOptionVisual { unselected, selected, correct, wrong }

WebPlayerOptionVisual webPlayerOptionVisual({
  required TestQuestion q,
  required String optionKey,
  /// When false (exam in progress), only selection highlight is shown.
  required bool revealAnswerKey,
  String? selectedOption,
  bool timedOut = false,
}) {
  final key = optionKey.toLowerCase();
  final selected = selectedOption?.toLowerCase() == key;
  final isCorrect = q.correctOption.toLowerCase() == key;

  if (revealAnswerKey) {
    if (timedOut) {
      if (isCorrect) return WebPlayerOptionVisual.correct;
      return WebPlayerOptionVisual.unselected;
    }
    if (isCorrect) return WebPlayerOptionVisual.correct;
    if (selected && !isCorrect) return WebPlayerOptionVisual.wrong;
    return WebPlayerOptionVisual.unselected;
  }

  if (selected) return WebPlayerOptionVisual.selected;
  return WebPlayerOptionVisual.unselected;
}

/// Top two rows aligned with test engine: context + language + dark mode, then grid + timer.
class WebPlayerSessionChrome extends StatelessWidget {
  const WebPlayerSessionChrome({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
    required this.contextLine,
    required this.uiLanguage,
    required this.onLanguageChanged,
    required this.onOpenQuestionGrid,
    required this.onToggleDarkMode,
    this.timed = false,
    this.remainingSecs = 0,
    this.examRemainingSecs = 0,
    this.sessionMode = 'learning',
    this.reviewMode = false,
    this.onSubmitTest,
  });

  final int currentIndex;
  final int totalQuestions;
  final String contextLine;
  final String uiLanguage;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onOpenQuestionGrid;
  final VoidCallback onToggleDarkMode;
  final bool timed;
  /// Per-question countdown (learning).
  final int remainingSecs;
  /// Whole-test countdown (exam).
  final int examRemainingSecs;
  /// `learning` | `exam`
  final String sessionMode;
  final bool reviewMode;
  /// Learning + exam: opens question grid; sheet includes Submit to end test.
  final VoidCallback? onSubmitTest;

  static String _mmss(int total) {
    final mm = (total ~/ 60).toString().padLeft(2, '0');
    final ss = (total % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Color _learningTimerColor() {
    if (remainingSecs > 30) return AppColors.correct;
    if (remainingSecs >= 10) return AppColors.warning;
    return AppColors.wrong;
  }

  Color _examTimerColor(BuildContext context, int remain) {
    final scheme = Theme.of(context).colorScheme;
    if (remain <= 300) return AppColors.wrong;
    return scheme.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;

    return Material(
      color: scheme.surface,
      elevation: isDark ? 0 : 1,
      shadowColor: scheme.shadow.withValues(alpha: isDark ? 0.5 : 0.12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
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
                        reviewMode
                            ? 'Review · Q${currentIndex + 1} of $totalQuestions'
                            : 'Q${currentIndex + 1} of $totalQuestions',
                        style: AppTextStyles.label().copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        contextLine,
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ToggleButtons(
                  isSelected: [
                    uiLanguage == 'en',
                    uiLanguage == 'hi',
                  ],
                  onPressed: (index) =>
                      onLanguageChanged(index == 0 ? 'en' : 'hi'),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  constraints: const BoxConstraints(
                    minHeight: 28,
                    minWidth: 60,
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('EN'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('हि'),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                InkWell(
                  onTap: onToggleDarkMode,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: onOpenQuestionGrid,
                  style: WebPlayerUiTokens.outlineIconSquare(context),
                  child: const Icon(Icons.grid_view_outlined, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (timed && !reviewMode && sessionMode == 'learning')
                  Text(
                    _mmss(remainingSecs.clamp(0, 1 << 20)),
                    style: AppTextStyles.label().copyWith(
                      color: _learningTimerColor(),
                    ),
                  ),
                if (timed && !reviewMode && sessionMode == 'exam')
                  Text(
                    _mmss(examRemainingSecs.clamp(0, 1 << 20)),
                    style: AppTextStyles.label().copyWith(
                      color: _examTimerColor(context, examRemainingSecs),
                    ),
                  ),
                const Spacer(),
                if (onSubmitTest != null && !reviewMode)
                  ElevatedButton(
                    onPressed: onSubmitTest,
                    style: WebPlayerUiTokens.destructiveCta(
                      context,
                      isDark: isDark,
                      scheme: scheme,
                    ),
                    child: const Text('Submit'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Option row matching test engine card + badge styling.
class WebPlayerOptionTile extends StatelessWidget {
  const WebPlayerOptionTile({
    super.key,
    required this.keyLabel,
    required this.optionText,
    required this.visual,
    this.onTap,
    this.confidenceStored,
    this.showConfidenceHeader = false,
    this.confidenceFooter,
  });

  final String keyLabel;
  final String optionText;
  final WebPlayerOptionVisual visual;
  final VoidCallback? onTap;
  final String? confidenceStored;
  final bool showConfidenceHeader;
  /// Exam confidence row inside the same card as the option (in-app pattern).
  final Widget? confidenceFooter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;

    late Color bg;
    late Color border;
    late Color text;
    late Color badgeBg;
    late Color badgeText;
    late double borderWidth;

    switch (visual) {
      case WebPlayerOptionVisual.unselected:
        bg = scheme.surface;
        border = isDark ? AppColors.borderDark : AppColors.borderLight;
        text = scheme.onSurface;
        badgeBg = scheme.surfaceContainerLow;
        badgeText = scheme.onSurfaceVariant;
        borderWidth = 0.5;
      case WebPlayerOptionVisual.selected:
        bg = isDark ? AppColors.primaryDeep : AppColors.primaryLight;
        border = AppColors.primary;
        text = isDark ? AppColors.onPrimary : AppColors.primaryDeep;
        badgeBg = AppColors.primary;
        badgeText = AppColors.onPrimary;
        borderWidth = 2;
      case WebPlayerOptionVisual.correct:
        bg = isDark ? AppColors.correctBgDark : AppColors.correctBg;
        border = AppColors.correct;
        text = isDark ? AppColors.correctTextDark : AppColors.correctText;
        badgeBg = AppColors.correct;
        badgeText = AppColors.onPrimary;
        borderWidth = 2;
      case WebPlayerOptionVisual.wrong:
        bg = isDark ? AppColors.wrongBgDark : AppColors.wrongBg;
        border = AppColors.wrong;
        text = isDark ? AppColors.wrongTextDark : AppColors.wrongText;
        badgeBg = AppColors.wrong;
        badgeText = AppColors.onPrimary;
        borderWidth = 2;
    }

    final hasFooter = confidenceFooter != null;

    Color? confStrip;
    var missingConf = false;
    if (!hasFooter &&
        showConfidenceHeader &&
        visual != WebPlayerOptionVisual.unselected) {
      switch (confidenceStored) {
        case AnswerConfidence.verySure:
          confStrip = AppColors.correct;
        case AnswerConfidence.somewhatSure:
          confStrip = AppColors.warning;
        case AnswerConfidence.guessing:
          confStrip = scheme.tertiary;
        default:
          missingConf = true;
      }
    }

    final outerRadius = BorderRadius.circular(AppRadius.md);
    final optionInkRadius = hasFooter
        ? const BorderRadius.vertical(top: Radius.circular(AppRadius.md))
        : BorderRadius.circular(AppRadius.md);

    final optionRow = onTap != null
        ? Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: optionInkRadius,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: Container(
                          width: 24,
                          height: 24,
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
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: AppTextStyles.option().copyWith(color: text),
                          children: doubleAsteriskBoldInlineSpans(
                            optionText,
                            AppTextStyles.option().copyWith(color: text),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: Container(
                      width: 24,
                      height: 24,
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
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: SelectableCopySearchText(
                    optionText,
                    style: AppTextStyles.option().copyWith(color: text),
                  ),
                ),
              ],
            ),
          );

    Widget inner = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        optionRow,
        if (hasFooter) ...[
          Divider(
            height: 1,
            thickness: 1,
            color: border.withValues(alpha: isDark ? 0.45 : 0.35),
          ),
          confidenceFooter!,
        ],
      ],
    );

    if (confStrip != null) {
      inner = Stack(
        clipBehavior: Clip.none,
        children: [
          inner,
          Positioned(
            top: 0,
            left: 12,
            right: 12,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: confStrip,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(2),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (missingConf && showConfidenceHeader) {
      inner = CustomPaint(
        painter: _WebPlayerDashedRRectPainter(
          color: scheme.outline,
          radius: AppRadius.md,
        ),
        child: inner,
      );
    }

    return ClipRRect(
      borderRadius: outerRadius,
      child: Material(
        color: AppColors.transparent,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: outerRadius,
            border: Border.all(color: border, width: borderWidth),
          ),
          child: inner,
        ),
      ),
    );
  }
}

/// Optional tiers after the answer is locked (normal / exam mode).
/// No caption line — selection is shown only via checkmark on the active tier,
/// same as in-app [ExamOptionConfidenceStrip] tier toggles.
class WebPlayerExamConfidenceStrip extends StatelessWidget {
  const WebPlayerExamConfidenceStrip({
    super.key,
    required this.confidence,
    required this.enabled,
    required this.onTierPressed,
  });

  final String? confidence;
  final bool enabled;
  final void Function(String tier) onTierPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _WebPlayerExamTierToggle(
                label: 'Sure',
                maxLines: 2,
                selected: confidence == AnswerConfidence.verySure,
                accent: AppColors.correct,
                onSurface: AppColors.onPrimary,
                labelUnselected: isDark
                    ? AppColors.correctTextDark
                    : AppColors.correctText,
                isDark: isDark,
                enabled: enabled,
                onTap: () => onTierPressed(AnswerConfidence.verySure),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _WebPlayerExamTierToggle(
                label: 'Educated\nguess',
                maxLines: 2,
                selected: confidence == AnswerConfidence.somewhatSure,
                accent: AppColors.warning,
                onSurface: Colors.white,
                labelUnselected: isDark
                    ? AppColors.warningTextDark
                    : AppColors.warningText,
                isDark: isDark,
                enabled: enabled,
                onTap: () => onTierPressed(AnswerConfidence.somewhatSure),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _WebPlayerExamTierToggle(
                label: 'Pure guess',
                maxLines: 2,
                selected: confidence == AnswerConfidence.guessing,
                accent: AppColors.info,
                onSurface: AppColors.onPrimary,
                labelUnselected: isDark
                    ? AppColors.infoTextDark
                    : AppColors.infoText,
                isDark: isDark,
                enabled: enabled,
                onTap: () => onTierPressed(AnswerConfidence.guessing),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebPlayerExamTierToggle extends StatelessWidget {
  const _WebPlayerExamTierToggle({
    required this.label,
    required this.maxLines,
    required this.selected,
    required this.accent,
    required this.onSurface,
    required this.labelUnselected,
    required this.isDark,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final int maxLines;
  final bool selected;
  final Color accent;
  final Color onSurface;
  final Color labelUnselected;
  final bool isDark;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? accent
        : accent.withValues(alpha: isDark ? 0.38 : 0.42);
    final border = Border.all(
      color: borderColor,
      width: selected ? 2.5 : 1,
    );
    final inactiveDim = !enabled && !selected;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: AnimatedOpacity(
          opacity: inactiveDim ? 0.42 : 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            decoration: BoxDecoration(
              color: selected
                  ? accent
                  : accent.withValues(alpha: isDark ? 0.07 : 0.06),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: border,
              boxShadow: selected && enabled
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: isDark ? 0.42 : 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : selected && !enabled
                      ? [
                          BoxShadow(
                            color: accent.withValues(
                              alpha: isDark ? 0.22 : 0.18,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.xs,
              ),
              child: Align(
                alignment: Alignment.center,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (selected)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: onSurface,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: maxLines,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSm().copyWith(
                          color: selected ? onSurface : labelUnselected,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w500,
                          height: 1.2,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WebPlayerLegendItem extends StatelessWidget {
  const _WebPlayerLegendItem({
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
    final swatch = Container(
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
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
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

/// Read-only attempt snapshot for palette cells (uuid → revealed, confidence, selection).
typedef WebPlayerAttemptLookup = ({
  bool revealed,
  bool examAnswered,
  String? selectedOption,
  String? confidence,
}) Function(String questionUuid);

Future<void> showWebPlayerQuestionGridSheet({
  required BuildContext context,
  required List<TestQuestion> questions,
  required WebPlayerAttemptLookup attemptFor,
  required int currentIndex,
  required ValueChanged<int> onJumpToIndex,
  bool showSubmitPanel = false,
  bool isExamMode = true,
  Future<void> Function()? onSubmitTest,
}) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  var examAttempted = 0;
  var examSkipped = 0;
  var learningAnswered = 0;
  for (final q in questions) {
    final a = attemptFor(q.uuid);
    if (showSubmitPanel) {
      if (isExamMode) {
        if (a.examAnswered) {
          examAttempted++;
        } else {
          examSkipped++;
        }
      } else if (a.revealed) {
        learningAnswered++;
      }
    }
  }
  final learningRemaining =
      showSubmitPanel && !isExamMode ? questions.length - learningAnswered : 0;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (ctx, scrollController) {
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
            child: ListView(
              controller: scrollController,
              children: [
                Text(
                  'Question Grid',
                  style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tap any number to jump to that question',
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  children: [
                    const _WebPlayerLegendItem(
                      label: 'Current',
                      bg: AppColors.primary,
                      fg: AppColors.onPrimary,
                    ),
                    _WebPlayerLegendItem(
                      label: 'Attempted',
                      bg: isDark ? AppColors.correctBgDark : AppColors.correctBg,
                      fg: isDark ? AppColors.correctTextDark : AppColors.correctText,
                    ),
                    _WebPlayerLegendItem(
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
                          onJumpToIndex(i);
                        },
                        child: _WebPlayerPaletteCell(
                          index: i,
                          currentIndex: currentIndex,
                          question: questions[i],
                          attempt: attemptFor(questions[i].uuid),
                          isDark: isDark,
                        ),
                      ),
                  ],
                ),
                if (showSubmitPanel) ...[
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
                          children: isExamMode
                              ? [
                                  _WebPlayerPaletteCountCell(
                                    label: 'Attempted',
                                    value: '$examAttempted',
                                    scheme: scheme,
                                  ),
                                  _WebPlayerPaletteCountCell(
                                    label: 'Skipped',
                                    value: '$examSkipped',
                                    scheme: scheme,
                                  ),
                                  _WebPlayerPaletteCountCell(
                                    label: 'Flagged',
                                    value: '0',
                                    scheme: scheme,
                                  ),
                                ]
                              : [
                                  _WebPlayerPaletteCountCell(
                                    label: 'Answered',
                                    value: '$learningAnswered',
                                    scheme: scheme,
                                  ),
                                  _WebPlayerPaletteCountCell(
                                    label: 'To go',
                                    value: '$learningRemaining',
                                    scheme: scheme,
                                  ),
                                  _WebPlayerPaletteCountCell(
                                    label: 'Flagged',
                                    value: '0',
                                    scheme: scheme,
                                  ),
                                ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (showSubmitPanel && onSubmitTest != null)
                  SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: WebPlayerUiTokens.outlineFullWidth(ctx),
                            child: const Text('Go back'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              await onSubmitTest();
                            },
                            style: WebPlayerUiTokens.destructiveCta(
                              ctx,
                              isDark: isDark,
                              scheme: scheme,
                            ),
                            child: Text(isExamMode ? 'Submit Test' : 'Submit'),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: WebPlayerUiTokens.outlineFullWidth(ctx),
                      child: const Text('Go back'),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _WebPlayerPaletteCountCell extends StatelessWidget {
  const _WebPlayerPaletteCountCell({
    required this.label,
    required this.value,
    required this.scheme,
  });

  final String label;
  final String value;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
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

class _WebPlayerPaletteCell extends StatelessWidget {
  const _WebPlayerPaletteCell({
    required this.index,
    required this.currentIndex,
    required this.question,
    required this.attempt,
    required this.isDark,
  });

  final int index;
  final int currentIndex;
  final TestQuestion question;
  final ({
    bool revealed,
    bool examAnswered,
    String? selectedOption,
    String? confidence,
  })
  attempt;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visited = attempt.revealed || attempt.examAnswered;
    Color bg;
    Color fg;

    if (index == currentIndex) {
      bg = AppColors.primary;
      fg = AppColors.onPrimary;
    } else if (visited) {
      bg = isDark ? AppColors.correctBgDark : AppColors.correctBg;
      fg = isDark ? AppColors.correctTextDark : AppColors.correctText;
    } else {
      bg = scheme.surfaceContainerLow;
      fg = scheme.onSurfaceVariant;
    }

    final cell = Container(
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

    return cell;
  }
}

/// Same geometry as test engine `_DashedRRectPainter`.
class _WebPlayerDashedRRectPainter extends CustomPainter {
  _WebPlayerDashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 1.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - 2 * inset,
        size.height - 2 * inset,
      ),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dashLen = 3.5;
      const gapLen = 3.0;
      while (distance < metric.length) {
        final next = min(distance + dashLen, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WebPlayerDashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
