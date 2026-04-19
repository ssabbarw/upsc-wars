import 'dart:math' show min;

import 'package:flutter/material.dart';

import 'package:upsc_wars/core/domain/entities/answer_confidence.dart';
import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/shared/extensions/context_extensions.dart';
import 'package:upsc_wars/shared/widgets/selectable_copy_search_text.dart';

/// Mirrors learning-mode option styling from [TestEngineScreen] `_OptionRow`.
enum ShareWebOptionVisual { unselected, selected, correct, wrong }

ShareWebOptionVisual shareWebOptionVisual({
  required TestQuestion q,
  required String optionKey,
  required bool revealed,
  String? selectedOption,
  bool timedOut = false,
}) {
  final key = optionKey.toLowerCase();
  final selected = selectedOption?.toLowerCase() == key;
  final isCorrect = q.correctOption.toLowerCase() == key;

  if (revealed) {
    if (timedOut) {
      if (isCorrect) return ShareWebOptionVisual.correct;
      return ShareWebOptionVisual.unselected;
    }
    if (isCorrect) return ShareWebOptionVisual.correct;
    if (selected && !isCorrect) return ShareWebOptionVisual.wrong;
    return ShareWebOptionVisual.unselected;
  }

  if (selected) return ShareWebOptionVisual.selected;
  return ShareWebOptionVisual.unselected;
}

/// Top two rows aligned with test engine: context + language + dark mode, then grid + timer.
class ShareWebSessionChrome extends StatelessWidget {
  const ShareWebSessionChrome({
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
    this.reviewMode = false,
  });

  final int currentIndex;
  final int totalQuestions;
  final String contextLine;
  final String uiLanguage;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onOpenQuestionGrid;
  final VoidCallback onToggleDarkMode;
  final bool timed;
  final int remainingSecs;
  final bool reviewMode;

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
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                  ),
                  child: const Icon(Icons.grid_view_outlined, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (timed && !reviewMode)
                  Text(
                    _mmss(remainingSecs.clamp(0, 1 << 20)),
                    style: AppTextStyles.label().copyWith(
                      color: _learningTimerColor(),
                    ),
                  ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Option row matching test engine card + badge styling.
class ShareWebOptionTile extends StatelessWidget {
  const ShareWebOptionTile({
    super.key,
    required this.keyLabel,
    required this.optionText,
    required this.visual,
    this.onTap,
    this.confidenceStored,
    this.showConfidenceHeader = false,
  });

  final String keyLabel;
  final String optionText;
  final ShareWebOptionVisual visual;
  final VoidCallback? onTap;
  final String? confidenceStored;
  final bool showConfidenceHeader;

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
      case ShareWebOptionVisual.unselected:
        bg = scheme.surface;
        border = isDark ? AppColors.borderDark : AppColors.borderLight;
        text = scheme.onSurface;
        badgeBg = scheme.surfaceContainerLow;
        badgeText = scheme.onSurfaceVariant;
        borderWidth = 0.5;
      case ShareWebOptionVisual.selected:
        bg = isDark ? AppColors.primaryDeep : AppColors.primaryLight;
        border = AppColors.primary;
        text = isDark ? AppColors.onPrimary : AppColors.primaryDeep;
        badgeBg = AppColors.primary;
        badgeText = AppColors.onPrimary;
        borderWidth = 2;
      case ShareWebOptionVisual.correct:
        bg = isDark ? AppColors.correctBgDark : AppColors.correctBg;
        border = AppColors.correct;
        text = isDark ? AppColors.correctTextDark : AppColors.correctText;
        badgeBg = AppColors.correct;
        badgeText = AppColors.onPrimary;
        borderWidth = 2;
      case ShareWebOptionVisual.wrong:
        bg = isDark ? AppColors.wrongBgDark : AppColors.wrongBg;
        border = AppColors.wrong;
        text = isDark ? AppColors.wrongTextDark : AppColors.wrongText;
        badgeBg = AppColors.wrong;
        badgeText = AppColors.onPrimary;
        borderWidth = 2;
    }

    Color? confStrip;
    var missingConf = false;
    if (showConfidenceHeader && visual != ShareWebOptionVisual.unselected) {
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

    Widget inner = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onTap != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.md),
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
                      child: Text(
                        optionText,
                        style: AppTextStyles.option().copyWith(color: text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Padding(
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
          ),
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
        painter: _ShareWebDashedRRectPainter(
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

class _ShareWebLegendItem extends StatelessWidget {
  const _ShareWebLegendItem({
    required this.label,
    required this.bg,
    required this.fg,
    this.dashedBorder = false,
  });

  final String label;
  final Color bg;
  final Color fg;
  final bool dashedBorder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget swatch = Container(
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
    if (dashedBorder) {
      swatch = CustomPaint(
        painter: _ShareWebDashedRRectPainter(
          color: scheme.outline,
          radius: 4,
        ),
        child: swatch,
      );
    }
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
typedef ShareWebAttemptLookup = ({
  bool revealed,
  String? selectedOption,
  String? confidence,
}) Function(String questionUuid);

Future<void> showShareWebQuestionGridSheet({
  required BuildContext context,
  required List<TestQuestion> questions,
  required ShareWebAttemptLookup attemptFor,
  required int currentIndex,
  required ValueChanged<int> onJumpToIndex,
}) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  var missingConfidence = 0;
  for (final q in questions) {
    final a = attemptFor(q.uuid);
    if (a.revealed && a.selectedOption != null && a.confidence == null) {
      missingConfidence++;
    }
  }

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
                    const _ShareWebLegendItem(
                      label: 'Current',
                      bg: AppColors.primary,
                      fg: AppColors.onPrimary,
                    ),
                    _ShareWebLegendItem(
                      label: 'Attempted',
                      bg: isDark ? AppColors.correctBgDark : AppColors.correctBg,
                      fg: isDark ? AppColors.correctTextDark : AppColors.correctText,
                    ),
                    _ShareWebLegendItem(
                      label: 'Not visited',
                      bg: scheme.surfaceContainerLow,
                      fg: scheme.onSurfaceVariant,
                    ),
                    const _ShareWebLegendItem(
                      label: 'Sure',
                      bg: AppColors.correct,
                      fg: AppColors.onPrimary,
                    ),
                    const _ShareWebLegendItem(
                      label: 'Intelligent',
                      bg: AppColors.warning,
                      fg: AppColors.onPrimary,
                    ),
                    _ShareWebLegendItem(
                      label: 'Pure guess',
                      bg: scheme.tertiary,
                      fg: scheme.onTertiary,
                    ),
                    _ShareWebLegendItem(
                      label: 'No confidence',
                      bg: scheme.surfaceContainerLow,
                      fg: scheme.onSurfaceVariant,
                      dashedBorder: true,
                    ),
                  ],
                ),
                if (missingConfidence > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Logging confidence helps spot blind spots and calibrate revision — '
                      '$missingConfidence answered question${missingConfidence == 1 ? '' : 's'} '
                      'have no confidence yet (dashed outline on the grid).',
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
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
                        child: _ShareWebPaletteCell(
                          index: i,
                          currentIndex: currentIndex,
                          question: questions[i],
                          attempt: attemptFor(questions[i].uuid),
                          isDark: isDark,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
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

class _ShareWebPaletteCell extends StatelessWidget {
  const _ShareWebPaletteCell({
    required this.index,
    required this.currentIndex,
    required this.question,
    required this.attempt,
    required this.isDark,
  });

  final int index;
  final int currentIndex;
  final TestQuestion question;
  final ({bool revealed, String? selectedOption, String? confidence}) attempt;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visited = attempt.revealed;
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

    final scored = visited && attempt.selectedOption != null;

    Color? confStrip;
    var missingConf = false;
    if (scored) {
      switch (attempt.confidence) {
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

    Widget cell = Container(
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

    if (confStrip != null) {
      cell = Stack(
        clipBehavior: Clip.none,
        children: [
          cell,
          Positioned(
            top: 0,
            left: 3,
            right: 3,
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
    } else if (missingConf) {
      cell = CustomPaint(
        painter: _ShareWebDashedRRectPainter(
          color: scheme.outline,
          radius: AppRadius.sm,
        ),
        child: cell,
      );
    }

    return cell;
  }
}

/// Same geometry as test engine `_DashedRRectPainter`.
class _ShareWebDashedRRectPainter extends CustomPainter {
  _ShareWebDashedRRectPainter({required this.color, required this.radius});

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
  bool shouldRepaint(covariant _ShareWebDashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
