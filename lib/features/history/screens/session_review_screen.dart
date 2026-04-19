import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/core/domain/entities/answer_confidence.dart';
import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/core/providers/catalog_providers.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/providers/prefs_provider.dart';
import 'package:upsc_wars/core/providers/user_database_provider.dart';
import 'package:upsc_wars/shared/extensions/context_extensions.dart';
import 'package:upsc_wars/shared/theme/dark_mode_toggle.dart';
import 'package:upsc_wars/shared/widgets/question_table_view.dart';
import 'package:upsc_wars/shared/widgets/selectable_copy_search_text.dart';
import 'package:upsc_wars/features/history/providers/review_session_provider.dart';
import 'package:upsc_wars/features/history/widgets/explanation_card.dart';

String _reviewConfidenceCaption(String? stored) {
  final v = (stored ?? '').trim();
  if (v.isEmpty) {
    return 'Confidence: —';
  }
  return 'Confidence: ${AnswerConfidence.examShortLabel(v)}';
}

Color _reviewConfidenceCaptionColor({
  required TestQuestion question,
  required ColorScheme scheme,
  required bool isDark,
}) {
  final conf = question.confidence;
  if (!AnswerConfidence.isDangerouslyConfident(conf)) {
    return scheme.onSurfaceVariant;
  }
  if (question.status == 'wrong') {
    return isDark ? AppColors.wrongTextDark : AppColors.wrongText;
  }
  if (question.status == 'correct') {
    return isDark ? AppColors.correctTextDark : AppColors.correctText;
  }
  return scheme.onSurfaceVariant;
}

class SessionReviewScreen extends HookConsumerWidget {
  const SessionReviewScreen({
    super.key,
    required this.sessionId,
    this.focusWrong = false,
  });

  final String sessionId;
  final bool focusWrong;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (sessionId: sessionId, focusWrong: focusWrong);
    final review = ref.watch(reviewSessionProvider(params));
    return Scaffold(
      body: SafeArea(
        child: review.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(
            child: FilledButton(
              onPressed: () => ref.invalidate(reviewSessionProvider(params)),
              child: const Text('Retry'),
            ),
          ),
          data: (state) {
            final index = useState(0);
            final uiLanguage = useState('en');
            final bookmarks = useState<Map<String, bool>>(
              state.bookmarkedByUuid,
            );
            final queue = useState<Map<String, bool>>(state.queuedByUuid);
            final q = state.questions[index.value];
            final total = state.total;
            final current = index.value + 1;
            final correct = state.questions
                .where((e) => e.status == 'correct')
                .length;
            final wrong = state.questions
                .where((e) => e.status == 'wrong')
                .length;
            final isBookmarked = bookmarks.value[q.uuid] ?? false;
            final isQueued = queue.value[q.uuid] ?? false;
            return ReviewBody(
              title: 'Session review',
              showRevisionBadge: false,
              progressRight: '$correct correct · $wrong wrong',
              question: q,
              current: current,
              total: total,
              isBookmarked: isBookmarked,
              isQueued: isQueued,
              confidenceSessionId: sessionId,
              onToggleBookmark: () async {
                final repo = await ref.read(
                  testEngineRepositoryProvider.future,
                );
                if (isBookmarked) {
                  await repo.removeBookmark(q.uuid);
                } else {
                  await repo.addBookmark(q.uuid);
                }
                bookmarks.value = {...bookmarks.value, q.uuid: !isBookmarked};
                queue.value = {...queue.value, q.uuid: true};
              },
              onPrev: () {
                if (index.value > 0) index.value = index.value - 1;
              },
              onNext: () {
                if (current == total) {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                } else {
                  index.value = index.value + 1;
                }
              },
              onAddToRevision: () async {
                if (queue.value[q.uuid] == true) return;
                final userDb = ref.read(userDatabaseProvider);
                await userDb.revisionQueueDao.add(
                  id: reviewSessionUuid.v4(),
                  questionUuid: q.uuid,
                  dateAddedToQueue: DateTime.now(),
                );
                queue.value = {...queue.value, q.uuid: true};
              },
              uiLanguage: uiLanguage.value,
              onLanguageChanged: (lang) => uiLanguage.value = lang,
            );
          },
        ),
      ),
    );
  }
}

class ReviewBody extends StatelessWidget {
  const ReviewBody({
    required this.title,
    required this.showRevisionBadge,
    required this.progressRight,
    required this.question,
    required this.current,
    required this.total,
    required this.isBookmarked,
    required this.isQueued,
    required this.onToggleBookmark,
    required this.onPrev,
    required this.onNext,
    this.onAddToRevision,
    this.isRevisionMode = false,
    required this.uiLanguage,
    required this.onLanguageChanged,
    this.confidenceBanner,
    this.confidenceSessionId,
  });

  final String title;
  final bool showRevisionBadge;
  final String progressRight;
  final TestQuestion question;
  final int current;
  final int total;
  final bool isBookmarked;
  final bool isQueued;
  final VoidCallback onToggleBookmark;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback? onAddToRevision;
  final bool isRevisionMode;
  final String uiLanguage;
  final ValueChanged<String> onLanguageChanged;
  /// Optional headline for Danger Zone style review.
  final String? confidenceBanner;

  /// When set, a read-only confidence line is shown under the user’s chosen option.
  final String? confidenceSessionId;

  @override
  Widget build(BuildContext context) {
    final isHindi = uiLanguage == 'hi';
    final displayText = isHindi ? question.displayTextHi : question.displayText;
    final tableData = isHindi ? question.tableDataHi : question.tableData;
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    final progress = total == 0 ? 0.0 : current / total;
    final status = _statusFor(question.status, isRevisionMode, isDark);
    final parsed = _parseStatements(displayText);
    return Column(
      children: [
        _TopBar(
          title: title,
          isBookmarked: isBookmarked,
          showRevisionBadge: showRevisionBadge,
          onBookmark: onToggleBookmark,
          uiLanguage: uiLanguage,
          onLanguageChanged: onLanguageChanged,
        ),
        if (confidenceBanner != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    confidenceBanner!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Question $current of $total',
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    progressRight,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: showRevisionBadge
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  value: progress.clamp(0, 1),
                  color: scheme.primary,
                  backgroundColor: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            children: [
              _VerdictStrip(question: question, status: status),
              const SizedBox(height: 14),
              const Text(
                'QUESTION',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.5,
                  color: Color(0xFF888888), // neutral section heading
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              SelectableCopySearchText(
                parsed.stem,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.6,
                  color: scheme.onSurface,
                ),
              ),
              if (parsed.statements.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (final st in parsed.statements)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.fromLTRB(10, 6, 0, 6),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: scheme.outline.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                    ),
                    child: SelectableCopySearchText(
                      st,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.55,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
              if (question.hasTable && tableData != null) ...[
                SizedBox(
                  height:
                      parsed.stem.trim().isNotEmpty ||
                          parsed.statements.isNotEmpty
                      ? 10
                      : 0,
                ),
                QuestionTableView(table: tableData),
              ],
              const SizedBox(height: 8),
              _Options(
                question: question,
                isRevisionMode: isRevisionMode,
                uiLanguage: uiLanguage,
                confidenceSessionId: confidenceSessionId,
              ),
              const SizedBox(height: 14),
              const Text(
                'EXPLANATION',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.5,
                  color: Color(0xFF888888), // neutral section heading
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ExplanationCard(
                translation: QuestionTranslation(
                  finalExplanation: isHindi
                      ? question.finalExplanationHi
                      : question.finalExplanation,
                  statementAnalysis:
                      (isHindi
                              ? question.statementAnalysisHi
                              : question.statementAnalysis)
                          .map(
                            (e) => StatementAnalysisVm(
                              statement: e.label,
                              isCorrect: e.isCorrect,
                              reason: e.reason,
                            ),
                          )
                          .toList(),
                  eliminationLogic: isHindi
                      ? question.eliminationLogicHi
                      : question.eliminationLogic,
                  strongDistractor: isHindi
                      ? question.strongDistractorHi
                      : question.strongDistractor,
                  upscTrapExplanation: isHindi
                      ? question.upscTrapExplanationHi
                      : question.upscTrapExplanation,
                  conceptsUsed: question.conceptsUsed,
                ),
                showStatements:
                    (isHindi
                            ? question.statementAnalysisHi
                            : question.statementAnalysis)
                        .isNotEmpty,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: current == 1 ? null : onPrev,
                  child: const Text('← Prev'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                  ),
                  onPressed: onNext,
                  child: Text(current == total ? 'Done' : 'Next →'),
                ),
              ),
            ],
          ),
        ),
        if (!isRevisionMode)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: isQueued
                ? const Text(
                    'In revision queue',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1D9E75),
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : InkWell(
                    onTap: onAddToRevision,
                    child: Text(
                      'Add to revision queue',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}

class _TopBar extends HookConsumerWidget {
  const _TopBar({
    required this.title,
    required this.isBookmarked,
    required this.showRevisionBadge,
    required this.onBookmark,
    required this.uiLanguage,
    required this.onLanguageChanged,
  });
  final String title;
  final bool isBookmarked;
  final bool showRevisionBadge;
  final VoidCallback onBookmark;
  final String uiLanguage;
  final ValueChanged<String> onLanguageChanged;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.canPop() ? context.pop() : context.go('/'),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.7),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.chevron_left,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface,
            ),
          ),
          const Spacer(),
          if (showRevisionBadge)
            Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark
                    ? scheme.primaryContainer
                    : const Color(0xFFE1F5EE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Revision mode',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? scheme.onPrimaryContainer
                      : const Color(0xFF0F6E56),
                ),
              ),
            ),
          const SizedBox(width: 8),
          ToggleButtons(
            isSelected: [uiLanguage == 'en', uiLanguage == 'hi'],
            onPressed: (index) => onLanguageChanged(index == 0 ? 'en' : 'hi'),
            constraints: const BoxConstraints(minHeight: 28, minWidth: 36),
            borderRadius: BorderRadius.circular(8),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('EN'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('HI'),
              ),
            ],
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () async {
              await setDarkModeEnabledWithLoader(
                context: context,
                ref: ref,
                darkModeEnabled: !isDark,
              );
            },
            child: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              size: 20,
              color: const Color(0xFF888888),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onBookmark,
            child: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              size: 20,
              color: isBookmarked ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerdictStrip extends StatelessWidget {
  const _VerdictStrip({required this.question, required this.status});
  final TestQuestion question;
  final _VerdictStatus status;
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: status.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: status.pillBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: status.pillText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (status.showYouAndCorrect) ...[
                Text(
                  'You: (${(question.selectedOption ?? '').toLowerCase()})',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? scheme.error : const Color(0xFFA32D2D),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Correct: (${question.correctOption.toLowerCase()})',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? scheme.primary : const Color(0xFF3B6D11),
                  ),
                ),
              ] else
                Text(
                  status.showOnlyCorrect
                      ? '(${question.correctOption.toLowerCase()})'
                      : 'Your answer: (${(question.selectedOption ?? '').toLowerCase()})',
                  style: TextStyle(
                    fontSize: 12,
                    color: status.showOnlyCorrect
                        ? const Color(0xFF3B6D11)
                        : const Color(0xFF1D9E75),
                  ),
                ),
            ],
          ),
          if ((question.conceptAnchor ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            SelectableCopySearchText(
              question.conceptAnchor!.trim(),
              style: TextStyle(fontSize: 12, color: status.anchorColor),
            ),
          ],
        ],
      ),
    );
  }
}

class _Options extends ConsumerWidget {
  const _Options({
    required this.question,
    required this.isRevisionMode,
    required this.uiLanguage,
    this.confidenceSessionId,
  });
  final TestQuestion question;
  final bool isRevisionMode;
  final String uiLanguage;
  final String? confidenceSessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHindi = uiLanguage == 'hi';
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    final prefs = ref.watch(prefsServiceProvider).value;
    final confidenceOn = prefs?.confidenceTrackingEnabled ?? false;
    final scored =
        question.status == 'correct' || question.status == 'wrong';
    final selected = question.selectedOption?.toLowerCase();

    Widget? stripFor(String letter) {
      final sid = confidenceSessionId;
      if (sid == null || !confidenceOn || !scored) return null;
      if (selected != letter) return null;
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _reviewConfidenceCaption(question.confidence),
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: AnswerConfidence.isDangerouslyConfident(
                    question.confidence,
                  )
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: _reviewConfidenceCaptionColor(
                question: question,
                scheme: scheme,
                isDark: isDark,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        _OptionRow(
          letter: 'a',
          text: isHindi ? question.optionAHi : question.optionA,
          state: _optionState(question, 'a', isRevisionMode, isDark, scheme),
          confidenceBelow: stripFor('a'),
        ),
        _OptionRow(
          letter: 'b',
          text: isHindi ? question.optionBHi : question.optionB,
          state: _optionState(question, 'b', isRevisionMode, isDark, scheme),
          confidenceBelow: stripFor('b'),
        ),
        _OptionRow(
          letter: 'c',
          text: isHindi ? question.optionCHi : question.optionC,
          state: _optionState(question, 'c', isRevisionMode, isDark, scheme),
          confidenceBelow: stripFor('c'),
        ),
        _OptionRow(
          letter: 'd',
          text: isHindi ? question.optionDHi : question.optionD,
          state: _optionState(question, 'd', isRevisionMode, isDark, scheme),
          confidenceBelow: stripFor('d'),
        ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.letter,
    required this.text,
    required this.state,
    this.confidenceBelow,
  });
  final String letter;
  final String text;
  final _OptionState state;
  final Widget? confidenceBelow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasStrip = confidenceBelow != null;
    final radius = BorderRadius.circular(8);

    final optionBlock = Padding(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            letter,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: state.letterColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableCopySearchText(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: state.textColor,
              ),
            ),
          ),
          if (state.tag != null) ...[
            const SizedBox(width: 6),
            Container(
              margin: const EdgeInsets.only(top: 1),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: state.tagBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                state.tag!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: state.tagColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: state.bg,
        borderRadius: radius,
        border: Border.all(
          color: state.border,
          width: state.strong ? 1.5 : 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          optionBlock,
          if (hasStrip) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
            ColoredBox(
              color: scheme.surface.withValues(alpha: 0.35),
              child: confidenceBelow!,
            ),
          ],
        ],
      ),
    );
  }
}

class _ParsedStem {
  const _ParsedStem({required this.stem, required this.statements});
  final String stem;
  final List<String> statements;
}

_ParsedStem _parseStatements(String displayText) {
  final lines = displayText.split('\n');
  final statements = <String>[];
  final stem = <String>[];
  final reg = RegExp(r'^\s*\d+\.\s+');
  for (final line in lines) {
    if (reg.hasMatch(line.trim())) {
      statements.add(line.trim());
    } else {
      stem.add(line);
    }
  }
  return _ParsedStem(stem: stem.join('\n').trim(), statements: statements);
}

class _VerdictStatus {
  const _VerdictStatus({
    required this.label,
    required this.bg,
    required this.pillBg,
    required this.pillText,
    required this.anchorColor,
    required this.showYouAndCorrect,
    required this.showOnlyCorrect,
  });
  final String label;
  final Color bg;
  final Color pillBg;
  final Color pillText;
  final Color anchorColor;
  final bool showYouAndCorrect;
  final bool showOnlyCorrect;
}

_VerdictStatus _statusFor(String status, bool revisionMode, bool isDark) {
  if (revisionMode) {
    return _VerdictStatus(
      label: 'Correct answer',
      bg: isDark ? const Color(0xFF153126) : const Color(0xFFE1F5EE),
      pillBg: isDark ? const Color(0xFF275941) : const Color(0xFFC0DD97),
      pillText: isDark ? const Color(0xFFC8F5E0) : const Color(0xFF173404),
      anchorColor: isDark ? const Color(0xFF9FE1CB) : const Color(0xFF0F6E56),
      showYouAndCorrect: false,
      showOnlyCorrect: true,
    );
  }
  if (status == 'wrong') {
    return _VerdictStatus(
      label: 'Incorrect',
      bg: isDark ? const Color(0xFF3B1515) : const Color(0xFFFCEBEB),
      pillBg: isDark ? const Color(0xFF6A2C2C) : const Color(0xFFF09595),
      pillText: isDark ? const Color(0xFFF7CFCF) : const Color(0xFF501313),
      anchorColor: isDark ? const Color(0xFFF3B2B2) : const Color(0xFF993C1D),
      showYouAndCorrect: true,
      showOnlyCorrect: false,
    );
  }
  if (status == 'correct') {
    return _VerdictStatus(
      label: 'Correct',
      bg: isDark ? const Color(0xFF153126) : const Color(0xFFE1F5EE),
      pillBg: isDark ? const Color(0xFF275941) : const Color(0xFFC0DD97),
      pillText: isDark ? const Color(0xFFC8F5E0) : const Color(0xFF173404),
      anchorColor: isDark ? const Color(0xFF9FE1CB) : const Color(0xFF0F6E56),
      showYouAndCorrect: false,
      showOnlyCorrect: false,
    );
  }
  if (status == 'timed_out') {
    return _VerdictStatus(
      label: "Time's up",
      bg: isDark ? const Color(0xFF39290E) : const Color(0xFFFAEEDA),
      pillBg: isDark ? const Color(0xFF5B3F14) : const Color(0xFFFAEEDA),
      pillText: isDark ? const Color(0xFFF4D39E) : const Color(0xFF854F0B),
      anchorColor: isDark ? const Color(0xFFF4D39E) : const Color(0xFF854F0B),
      showYouAndCorrect: false,
      showOnlyCorrect: true,
    );
  }
  return _VerdictStatus(
    label: 'Skipped',
    bg: isDark ? const Color(0xFF39290E) : const Color(0xFFFAEEDA),
    pillBg: isDark ? const Color(0xFF5B3F14) : const Color(0xFFFAEEDA),
    pillText: isDark ? const Color(0xFFF4D39E) : const Color(0xFF854F0B),
    anchorColor: isDark ? const Color(0xFFF4D39E) : const Color(0xFF854F0B),
    showYouAndCorrect: false,
    showOnlyCorrect: true,
  );
}

class _OptionState {
  const _OptionState({
    required this.bg,
    required this.border,
    required this.letterColor,
    required this.textColor,
    required this.strong,
    this.tag,
    this.tagBg = Colors.transparent,
    this.tagColor = Colors.transparent,
  });
  final Color bg;
  final Color border;
  final Color letterColor;
  final Color textColor;
  final bool strong;
  final String? tag;
  final Color tagBg;
  final Color tagColor;
}

_OptionState _optionState(
  TestQuestion q,
  String letter,
  bool revisionMode,
  bool isDark,
  ColorScheme scheme,
) {
  final lower = letter.toLowerCase();
  final isCorrect = q.correctOption.toLowerCase() == lower;
  final isSelected = (q.selectedOption ?? '').toLowerCase() == lower;

  if (isCorrect) {
    return _OptionState(
      bg: isDark ? const Color(0xFF1E3320) : const Color(0xFFEAF3DE),
      border: isDark ? const Color(0xFF5F8A63) : const Color(0xFF97C459),
      letterColor: isDark ? const Color(0xFFA7D7AD) : const Color(0xFF3B6D11),
      textColor: scheme.onSurface,
      strong: true,
      tag: 'Correct',
      tagBg: isDark ? const Color(0xFF2F5B35) : const Color(0xFFC0DD97),
      tagColor: isDark ? const Color(0xFFD4F4D9) : const Color(0xFF173404),
    );
  }
  if (!revisionMode && q.status == 'wrong' && isSelected) {
    return _OptionState(
      bg: isDark ? const Color(0xFF3B1515) : const Color(0xFFFCEBEB),
      border: isDark ? const Color(0xFF8F4747) : const Color(0xFFF09595),
      letterColor: isDark ? const Color(0xFFE2A8A8) : const Color(0xFFA32D2D),
      textColor: scheme.onSurface,
      strong: true,
      tag: 'Your pick',
      tagBg: isDark ? const Color(0xFF6A2C2C) : const Color(0xFFF7C1C1),
      tagColor: isDark ? const Color(0xFFF7CFCF) : const Color(0xFF501313),
    );
  }
  final muted = revisionMode;
  return _OptionState(
    bg: scheme.surface,
    border: scheme.outlineVariant.withValues(alpha: 0.8),
    letterColor: scheme.onSurfaceVariant,
    textColor: muted ? scheme.onSurfaceVariant : scheme.onSurface,
    strong: false,
  );
}
