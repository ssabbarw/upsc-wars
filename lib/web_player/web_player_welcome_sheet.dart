import 'package:flutter/material.dart';

import 'package:upsc_wars/core/constants/app_constants.dart';
import 'package:upsc_wars/core/constants/timed_exam_debug_constants.dart';
import 'package:upsc_wars/core/deep_link/share_link_kind.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/shared/extensions/count_formatting.dart';
import 'package:upsc_wars/shared/widgets/test_config_sheet_widgets.dart';
import 'package:upsc_wars/web_player/web_player_ui_tokens.dart';

/// Result of the unified web welcome flow (mode + timing).
/// Matches in-app [SessionConfig] timing: exam uses [kDebugSecondsPerQuestion]
/// per question when timed; learning uses chosen seconds per question.
class WebPlayerWelcomeOutcome {
  const WebPlayerWelcomeOutcome({
    required this.sessionMode,
    required this.timed,
    required this.perQuestionSecs,
  });

  /// `learning` | `exam`
  final String sessionMode;
  final bool timed;
  final int perQuestionSecs;
}

/// One bottom sheet aligned with [TestConfigBottomSheet]: mode cards, fixed
/// question count (no picker), exam timed switch + app duration, learning
/// time tiles, and a configuration summary.
Future<WebPlayerWelcomeOutcome?> showWebPlayerWelcomeSheet({
  required BuildContext context,
  required ShareLinkKind kind,
  required String subject,
  required String? topic,
  required int questionCount,
  String? participantName,
  bool learningOnly = false,
  VoidCallback? onFeedbackPressed,
}) {
  return showModalBottomSheet<WebPlayerWelcomeOutcome>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _WebPlayerWelcomeSheetBody(
      kind: kind,
      subject: subject,
      topic: topic,
      questionCount: questionCount,
      participantName: participantName,
      learningOnly: learningOnly,
      onFeedbackPressed: onFeedbackPressed,
    ),
  );
}

class _WebPlayerWelcomeSheetBody extends StatefulWidget {
  const _WebPlayerWelcomeSheetBody({
    required this.kind,
    required this.subject,
    required this.topic,
    required this.questionCount,
    required this.participantName,
    required this.learningOnly,
    this.onFeedbackPressed,
  });

  final ShareLinkKind kind;
  final String subject;
  final String? topic;
  final int questionCount;
  final String? participantName;
  final bool learningOnly;
  final VoidCallback? onFeedbackPressed;

  @override
  State<_WebPlayerWelcomeSheetBody> createState() =>
      _WebPlayerWelcomeSheetBodyState();
}

class _WebPlayerWelcomeSheetBodyState extends State<_WebPlayerWelcomeSheetBody> {
  /// Default to Exam like in-app test config.
  String _sessionMode = 'exam';
  bool _examTimed = true;
  int _learningSecs = 60;

  String get _kindLabel => switch (widget.kind) {
        ShareLinkKind.question => 'Shared question',
        ShareLinkKind.battle => 'Shared set',
        ShareLinkKind.test => 'Shared test',
      };

  String get _topicLine {
    final t = widget.topic?.trim();
    if (t == null || t.isEmpty) return '';
    return t;
  }

  String get _helloLine {
    final name = widget.participantName?.trim();
    if (name == null || name.isEmpty) return '';
    return 'Hello $name';
  }

  bool get _isLearning =>
      widget.learningOnly || _sessionMode == 'learning';

  String _formatExamDurationTotal() {
    final n = widget.questionCount < 1 ? 1 : widget.questionCount;
    final totalSecs = n * kDebugSecondsPerQuestion;
    final minutes = (totalSecs / 60).round();
    return '$minutes minutes total';
  }

  void _popWithOutcome() {
    final mode = widget.learningOnly ? 'learning' : _sessionMode;
    final timed = mode == 'exam' ? _examTimed : true;
    final perQ =
        mode == 'exam' ? kDebugSecondsPerQuestion : _learningSecs;
    Navigator.of(context).pop(
      WebPlayerWelcomeOutcome(
        sessionMode: mode,
        timed: timed,
        perQuestionSecs: perQ,
      ),
    );
  }

  String _startLabel() {
    if (widget.learningOnly || _sessionMode == 'learning') {
      return 'Start learning session';
    }
    return 'Start exam';
  }

  ButtonStyle _startButtonStyle(BuildContext context, ColorScheme scheme) {
    final isExam = !widget.learningOnly && _sessionMode == 'exam';
    if (isExam) {
      return ElevatedButton.styleFrom(
        backgroundColor: AppColors.info,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: scheme.surfaceContainerLow,
        disabledForegroundColor: scheme.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(vertical: 15),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        elevation: 0,
        textStyle: AppTextStyles.label(),
      );
    }
    return WebPlayerUiTokens.primaryCta(context);
  }

  String _timingSummaryLine() {
    if (_isLearning) {
      return '${_learningSecs}s per question';
    }
    if (!_examTimed) {
      return 'Untimed — no countdown for this exam';
    }
    return 'Timed — ${_formatExamDurationTotal()} '
        '(${kDebugSecondsPerQuestion}s × ${widget.questionCount} questions)';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final maxH = MediaQuery.sizeOf(context).height * 0.92;
    final sheetBg = theme.bottomSheetTheme.backgroundColor ??
        (isDark ? AppColors.surfacePrimaryDark : AppColors.surfacePrimaryLight);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.sm,
        right: AppSpacing.sm,
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.sm,
      ),
      child: SizedBox(
        height: maxH,
        child: Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: AppColors.gray900.withValues(alpha: isDark ? 0.45 : 0.14),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.xs,
                  0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 40,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: borderColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.xs,
                    AppSpacing.xxl,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_helloLine.isNotEmpty) ...[
                        Text(
                          _helloLine,
                          style: AppTextStyles.h3().copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      Text(
                        widget.subject,
                        style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (_topicLine.isNotEmpty) ...[
                        Text(
                          _topicLine,
                          style: AppTextStyles.bodyMd().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                      Text(
                        _kindLabel,
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Text(
                        'Number of questions',
                        style: AppTextStyles.label().copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: borderColor, width: 0.5),
                        ),
                        child: Text(
                          '${formatIntCount(widget.questionCount)} questions '
                          '(fixed for this link)',
                          style: AppTextStyles.bodySm().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (!widget.learningOnly) ...[
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          'Mode',
                          style: AppTextStyles.label().copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: TestConfigModeOptionCard(
                                title: 'Exam',
                                description:
                                    'Simulate real conditions. Explanation after test ends.',
                                icon: Icons.timer_outlined,
                                selected: _sessionMode == 'exam',
                                examStyle: true,
                                borderColor: borderColor,
                                onTap: () => setState(() => _sessionMode = 'exam'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: TestConfigModeOptionCard(
                                title: 'Learning',
                                description:
                                    'See explanation after each question.',
                                icon: Icons.lightbulb_outline,
                                selected: _sessionMode == 'learning',
                                examStyle: false,
                                borderColor: borderColor,
                                onTap: () =>
                                    setState(() => _sessionMode = 'learning'),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          'Learning practice',
                          style: AppTextStyles.label().copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Pick an option, log how sure you were, then see the '
                          'full explanation before the next question.',
                          style: AppTextStyles.bodyMd().copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ],
                      if (_isLearning) ...[
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          'Time per question',
                          style: AppTextStyles.label().copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: TestConfigLearningTimeTile(
                                label: '45s',
                                selected: _learningSecs == 45,
                                isDark: isDark,
                                onTap: () => setState(() => _learningSecs = 45),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TestConfigLearningTimeTile(
                                label: '1 min',
                                selected: _learningSecs == 60,
                                isDark: isDark,
                                onTap: () => setState(() => _learningSecs = 60),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TestConfigLearningTimeTile(
                                label: '2 min',
                                selected: _learningSecs == 120,
                                isDark: isDark,
                                onTap: () => setState(() => _learningSecs = 120),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: AppSpacing.xxl),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Timed test',
                              style: AppTextStyles.label().copyWith(
                                color: scheme.onSurface,
                              ),
                            ),
                            Switch(
                              value: _examTimed,
                              onChanged: (v) =>
                                  setState(() => _examTimed = v),
                              activeThumbColor: AppColors.onPrimary,
                              activeTrackColor: AppColors.info,
                            ),
                          ],
                        ),
                        if (_examTimed) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _formatExamDurationTotal(),
                            style: AppTextStyles.bodySm().copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                      _buildSummary(scheme, isDark),
                      const SizedBox(height: AppSpacing.lg),
                      if (widget.onFeedbackPressed != null)
                        Center(
                          child: TextButton.icon(
                            onPressed: widget.onFeedbackPressed,
                            icon: const Icon(Icons.email_outlined, size: 20),
                            label: const Text('Send feedback to team'),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  0,
                  AppSpacing.xxl,
                  AppSpacing.lg,
                ),
                child: ElevatedButton(
                  onPressed: _popWithOutcome,
                  style: _startButtonStyle(context, scheme),
                  child: Text(_startLabel()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(ColorScheme scheme, bool isDark) {
    final effectiveMode = widget.learningOnly ? 'learning' : _sessionMode;
    final modeTitle = effectiveMode == 'exam' ? 'Exam' : 'Learning';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Summary',
          style: AppTextStyles.label().copyWith(
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 0.6,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryRow(scheme, 'Subject', widget.subject),
                if (_topicLine.isNotEmpty)
                  _summaryRow(scheme, 'Topic', _topicLine),
                _summaryRow(
                  scheme,
                  'Questions',
                  '${formatIntCount(widget.questionCount)} (fixed)',
                ),
                _summaryRow(scheme, 'Mode', modeTitle),
                _summaryRow(scheme, 'Timing', _timingSummaryLine()),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Configured in this sheet',
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _configuredBullets(),
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'This test is brought to you by "${AppConstants.appDisplayName} mobile app".',
          style: AppTextStyles.bodyMd().copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  String _configuredBullets() {
    final parts = <String>[];
    if (widget.learningOnly) {
      parts.add('• Learning flow from this share link');
    } else if (_sessionMode == 'learning') {
      parts.add('• Learning mode — explanations after each question');
    } else {
      parts.add('• Exam mode — score the full set, then review');
    }
    if (_isLearning) {
      parts.add('• ${_learningSecs}s limit per question');
    } else if (_examTimed) {
      parts.add(
        '• Timed exam — $kDebugSecondsPerQuestion s per question '
        '(${_formatExamDurationTotal().toLowerCase()})',
      );
    } else {
      parts.add('• No timer — take as long as you need');
    }
    parts.add(
      '• ${formatIntCount(widget.questionCount)} questions from the shared set',
    );
    return parts.join('\n');
  }

  Widget _summaryRow(ColorScheme scheme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySm().copyWith(color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
