import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/answer_confidence.dart';
import '../../../core/domain/entities/session_config.dart';
import '../../../core/domain/entities/session_result.dart';
import '../../../core/domain/entities/test_question.dart';
import '../../../core/presentation/session_subject_label.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/responsive/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../history/widgets/explanation_card.dart';
import '../../home/providers/home_activation_provider.dart';
import '../push_spot_test_constants.dart';

class PushSpotResultsScreen extends ConsumerWidget {
  const PushSpotResultsScreen({super.key, required this.sessionId});

  final String sessionId;

  static EdgeInsets _contentPadding(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final outer = AppBreakpoints.fullScreenHPadding(screenW);
    return EdgeInsets.fromLTRB(
      outer.left + AppSpacing.lg,
      AppSpacing.md,
      outer.right + AppSpacing.lg,
      AppSpacing.md,
    );
  }

  static EdgeInsets _footerPadding(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final outer = AppBreakpoints.fullScreenHPadding(screenW);
    return EdgeInsets.fromLTRB(
      outer.left + AppSpacing.lg,
      AppSpacing.sm,
      outer.right + AppSpacing.lg,
      AppSpacing.sm,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(sessionResultProvider(sessionId));
    final questionAsync = ref.watch(_spotQuestionProvider(sessionId));
    final scheme = Theme.of(context).colorScheme;

    ref.listen(sessionResultProvider(sessionId), (prev, next) {
      if (next.hasValue && prev?.hasValue != true) {
        ref.invalidate(homeActivationProvider);
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/');
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          bottom: false,
          child: resultAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorBody(message: e.toString()),
            data: (result) {
              return questionAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorBody(message: e.toString()),
                data: (question) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: _contentPadding(
                        context,
                      ).copyWith(bottom: AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Quick check',
                            style: AppTextStyles.h2().copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'You already reviewed the explanation in the test.',
                            style: AppTextStyles.bodySm().copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: _contentPadding(context).copyWith(top: 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _CatalogContextCard(result: result),
                            const SizedBox(height: AppSpacing.md),
                            _AttemptCard(
                              question: question,
                              language: result.language,
                            ),
                            if (_confidenceNote(question) != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              _ConfidenceNote(text: _confidenceNote(question)!),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            _ReviewExplanationTile(
                              question: question,
                              language: result.language,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: resultAsync.maybeWhen(
          data: (result) => questionAsync.maybeWhen(
            data: (_) => _SpotResultsFooter(
              padding: _footerPadding(context),
              followUpLabel: _followUpLabel(result),
              onFollowUp: () => unawaited(_startFollowUp(context, ref, result)),
              onDone: () => context.go('/'),
            ),
            orElse: () => null,
          ),
          orElse: () => null,
        ),
      ),
    );
  }

  static String? _confidenceNote(TestQuestion question) {
    if (question.status != 'wrong') return null;
    final c = question.confidence;
    if (c == null || c.isEmpty) return null;
    if (AnswerConfidence.isDangerouslyConfident(c)) {
      return 'You were confident on this one — worth revisiting why it felt right.';
    }
    return null;
  }

  static String _followUpLabel(SessionResult result) {
    final topic = displayTopicLabel(result.topic);
    if (topic.isEmpty) {
      return 'Try ${PushSpotTestConstants.followUpQuestionCount} more';
    }
    return 'Try ${PushSpotTestConstants.followUpQuestionCount} more on $topic';
  }

  static Future<void> _startFollowUp(
    BuildContext context,
    WidgetRef ref,
    SessionResult result,
  ) async {
    final topic = result.topic?.trim();
    if (topic == null || topic.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Topic not available for follow-up.')),
        );
      }
      return;
    }
    try {
      final create = await ref.read(createSessionUseCaseProvider.future);
      final lang = await ref.read(appLanguageProvider.future);
      final id = await create.execute(
        SessionConfig(
          subject: result.subject,
          topic: topic,
          mode: 'learning',
          questionCount: PushSpotTestConstants.followUpQuestionCount,
          isTimed: false,
          language: lang,
          analyticsFeatureKey: PushSpotTestConstants.followUpAnalyticsKey,
        ),
      );
      if (!context.mounted) return;
      context.go('/test/$id');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not start follow-up: $e')));
    }
  }
}

final _spotQuestionProvider = FutureProvider.autoDispose
    .family<TestQuestion, String>((ref, sessionId) async {
      final load = await ref.watch(loadSessionUseCaseProvider.future);
      final active = await load.execute(sessionId);
      if (active.questions.isEmpty) {
        throw StateError('No questions in session');
      }
      return active.questions.first;
    });

class _SpotResultsFooter extends StatelessWidget {
  const _SpotResultsFooter({
    required this.padding,
    required this.followUpLabel,
    required this.onFollowUp,
    required this.onDone,
  });

  final EdgeInsets padding;
  final String followUpLabel;
  final VoidCallback onFollowUp;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Material(
      color: scheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: borderColor.withValues(alpha: 0.45)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: onFollowUp,
                    child: Text(
                      followUpLabel,
                      style: AppTextStyles.label().copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  onPressed: onDone,
                  child: Text(
                    'Done',
                    style: AppTextStyles.label().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogContextCard extends StatelessWidget {
  const _CatalogContextCard({required this.result});

  final SessionResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ContextRow(
            label: 'Subject',
            value: displayNameForSessionSubject(result.subject),
          ),
          if ((result.topic ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _ContextRow(label: 'Topic', value: displayTopicLabel(result.topic)),
          ],
          if ((result.subTopic ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _ContextRow(
              label: 'Subtopic',
              value: displayTopicLabel(result.subTopic),
              emphasize: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _ContextRow extends StatelessWidget {
  const _ContextRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: (emphasize ? AppTextStyles.label() : AppTextStyles.bodySm())
                .copyWith(
                  color: emphasize ? scheme.onSurface : scheme.onSurfaceVariant,
                  fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
                  height: 1.35,
                ),
          ),
        ),
      ],
    );
  }
}

class _AttemptCard extends StatelessWidget {
  const _AttemptCard({required this.question, required this.language});

  final TestQuestion question;
  final String language;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final correct = question.status == 'correct';
    final unattempted =
        question.status != 'correct' && question.status != 'wrong';
    final (bg, accent, verdict, icon) = switch ((correct, unattempted)) {
      (true, _) => (
        isDark ? AppColors.correctBgDark : AppColors.correctBg,
        isDark ? AppColors.correctTextDark : AppColors.correctText,
        'Correct',
        Icons.check_circle_rounded,
      ),
      (false, true) => (
        isDark ? AppColors.warningBgDark : AppColors.warningBg,
        isDark ? AppColors.warningTextDark : AppColors.warningText,
        'Not attempted',
        Icons.help_outline_rounded,
      ),
      (false, false) => (
        isDark ? AppColors.wrongBgDark : AppColors.wrongBg,
        isDark ? AppColors.wrongTextDark : AppColors.wrongText,
        'Incorrect',
        Icons.cancel_rounded,
      ),
    };

    final yourKey = question.selectedOption?.trim().toUpperCase();
    final correctKey = question.correctOption.trim().toUpperCase();
    final confidence = question.confidence;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Text(
                verdict,
                style: AppTextStyles.label().copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (!unattempted && yourKey != null && yourKey.isNotEmpty)
            _AttemptLine(
              label: 'Your answer',
              optionKey: yourKey,
              optionText: _optionText(question, yourKey, language),
              accent: accent,
            ),
          if (!unattempted &&
              yourKey != null &&
              yourKey.isNotEmpty &&
              correctKey.isNotEmpty)
            const SizedBox(height: AppSpacing.sm),
          if (correctKey.isNotEmpty)
            _AttemptLine(
              label: 'Correct answer',
              optionKey: correctKey,
              optionText: _optionText(question, correctKey, language),
              accent: scheme.onSurface,
            ),
          if (confidence != null && confidence.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _AttemptLine(
              label: 'Confidence',
              optionKey: null,
              optionText: AnswerConfidence.examShortLabel(confidence),
              accent: scheme.onSurfaceVariant,
            ),
          ],
          if (question.timeSpentSecs != null &&
              question.timeSpentSecs! > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            _AttemptLine(
              label: 'Time',
              optionKey: null,
              optionText: '${question.timeSpentSecs}s',
              accent: scheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
  }
}

class _AttemptLine extends StatelessWidget {
  const _AttemptLine({
    required this.label,
    required this.optionKey,
    required this.optionText,
    required this.accent,
  });

  final String label;
  final String? optionKey;
  final String optionText;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Text(
            label,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (optionKey != null) ...[
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Text(
              optionKey!,
              style: AppTextStyles.caption().copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Text(
            optionText,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurface,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewExplanationTile extends StatefulWidget {
  const _ReviewExplanationTile({
    required this.question,
    required this.language,
  });

  final TestQuestion question;
  final String language;

  @override
  State<_ReviewExplanationTile> createState() => _ReviewExplanationTileState();
}

class _ReviewExplanationTileState extends State<_ReviewExplanationTile> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Review explanation',
                      style: AppTextStyles.label().copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: AppSpacing.md),
                _ExplanationBlock(
                  question: widget.question,
                  language: widget.language,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfidenceNote extends StatelessWidget {
  const _ConfidenceNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.infoBgDark : AppColors.infoBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: (isDark ? AppColors.infoTextDark : AppColors.infoText)
              .withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySm().copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.35,
        ),
      ),
    );
  }
}

class _ExplanationBlock extends StatelessWidget {
  const _ExplanationBlock({required this.question, required this.language});

  final TestQuestion question;
  final String language;

  @override
  Widget build(BuildContext context) {
    final isHindi = language == 'hi';
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

    return ExplanationCard(
      translation: QuestionTranslation(
        finalExplanation: finalExplanation,
        statementAnalysis: statementAnalysis
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
    );
  }
}

String _optionText(TestQuestion question, String key, String language) {
  final k = key.toLowerCase();
  final isHi = language == 'hi';
  final text = switch (k) {
    'a' => isHi ? question.optionAHi : question.optionA,
    'b' => isHi ? question.optionBHi : question.optionB,
    'c' => isHi ? question.optionCHi : question.optionC,
    'd' => isHi ? question.optionDHi : question.optionD,
    _ => '',
  };
  return text.trim().isEmpty ? '—' : text.trim();
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
