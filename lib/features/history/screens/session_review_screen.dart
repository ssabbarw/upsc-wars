import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/core/providers/catalog_providers.dart';
import 'package:upsc_wars/core/providers/user_database_provider.dart';
import 'package:upsc_wars/features/history/providers/review_session_provider.dart';
import 'package:upsc_wars/features/history/widgets/explanation_card.dart';

class SessionReviewScreen extends HookConsumerWidget {
  const SessionReviewScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(reviewSessionProvider(sessionId));
    return Scaffold(
      body: SafeArea(
        child: review.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (e, st) => Center(
                child: FilledButton(
                  onPressed:
                      () => ref.invalidate(reviewSessionProvider(sessionId)),
                  child: const Text('Retry'),
                ),
              ),
          data: (state) {
            final index = useState(0);
            final bookmarks = useState<Map<String, bool>>(
              state.bookmarkedByUuid,
            );
            final queue = useState<Map<String, bool>>(state.queuedByUuid);
            final q = state.questions[index.value];
            final total = state.total;
            final current = index.value + 1;
            final correct =
                state.questions.where((e) => e.status == 'correct').length;
            final wrong =
                state.questions.where((e) => e.status == 'wrong').length;
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

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : current / total;
    final status = _statusFor(question.status, isRevisionMode);
    final parsed = _parseStatements(question.displayText);
    return Column(
      children: [
        _TopBar(
          title: title,
          isBookmarked: isBookmarked,
          showRevisionBadge: showRevisionBadge,
          onBookmark: onToggleBookmark,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Question $current of $total',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    progressRight,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          showRevisionBadge
                              ? const Color(0xFF1D9E75)
                              : const Color(0xFF888888),
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
                  color: const Color(0xFF1D9E75),
                  backgroundColor: Colors.black.withValues(alpha: 0.12),
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
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                parsed.stem,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.6,
                  color: Color(0xFF1A1A1A),
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
                          color: Colors.black.withValues(alpha: 0.22),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      st,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.55,
                        color: Color(0xFF555555),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              _Options(question: question, isRevisionMode: isRevisionMode),
              const SizedBox(height: 14),
              const Text(
                'EXPLANATION',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.5,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ExplanationCard(
                translation: QuestionTranslation(
                  finalExplanation: question.finalExplanation,
                  statementAnalysis:
                      question.statementAnalysis
                          .map(
                            (e) => StatementAnalysisVm(
                              statement: e.label,
                              isCorrect: e.isCorrect,
                              reason: e.reason,
                            ),
                          )
                          .toList(),
                  eliminationLogic: question.eliminationLogic,
                  strongDistractor: question.strongDistractor,
                  upscTrapExplanation: question.upscTrapExplanation,
                  conceptsUsed: question.conceptsUsed,
                ),
                showStatements: question.statementAnalysis.isNotEmpty,
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
                    backgroundColor: const Color(0xFF1D9E75),
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
            child:
                isQueued
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
                      child: const Text(
                        'Add to revision queue',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888888),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
          ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.isBookmarked,
    required this.showRevisionBadge,
    required this.onBookmark,
  });
  final String title;
  final bool isBookmarked;
  final bool showRevisionBadge;
  final VoidCallback onBookmark;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withValues(alpha: 0.12),
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
                color: const Color(0xFFF7F7F5),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.12),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chevron_left,
                size: 18,
                color: Color(0xFF555555),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const Spacer(),
          if (showRevisionBadge)
            Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE1F5EE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Revision mode',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F6E56),
                ),
              ),
            ),
          InkWell(
            onTap: onBookmark,
            child: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              size: 20,
              color:
                  isBookmarked
                      ? const Color(0xFF1D9E75)
                      : const Color(0xFF888888),
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFA32D2D),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Correct: (${question.correctOption.toLowerCase()})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3B6D11),
                  ),
                ),
              ] else
                Text(
                  status.showOnlyCorrect
                      ? '(${question.correctOption.toLowerCase()})'
                      : 'Your answer: (${(question.selectedOption ?? '').toLowerCase()})',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        status.showOnlyCorrect
                            ? const Color(0xFF3B6D11)
                            : const Color(0xFF1D9E75),
                  ),
                ),
            ],
          ),
          if ((question.conceptAnchor ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              question.conceptAnchor!.trim(),
              style: TextStyle(fontSize: 12, color: status.anchorColor),
            ),
          ],
        ],
      ),
    );
  }
}

class _Options extends StatelessWidget {
  const _Options({required this.question, required this.isRevisionMode});
  final TestQuestion question;
  final bool isRevisionMode;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _OptionRow(
          letter: 'a',
          text: question.optionA,
          state: _optionState(question, 'a', isRevisionMode),
        ),
        _OptionRow(
          letter: 'b',
          text: question.optionB,
          state: _optionState(question, 'b', isRevisionMode),
        ),
        _OptionRow(
          letter: 'c',
          text: question.optionC,
          state: _optionState(question, 'c', isRevisionMode),
        ),
        _OptionRow(
          letter: 'd',
          text: question.optionD,
          state: _optionState(question, 'd', isRevisionMode),
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
  });
  final String letter;
  final String text;
  final _OptionState state;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(
        color: state.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: state.border,
          width: state.strong ? 1.5 : 0.5,
        ),
      ),
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
            child: Text(
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

_VerdictStatus _statusFor(String status, bool revisionMode) {
  if (revisionMode) {
    return const _VerdictStatus(
      label: 'Correct answer',
      bg: Color(0xFFE1F5EE),
      pillBg: Color(0xFFC0DD97),
      pillText: Color(0xFF173404),
      anchorColor: Color(0xFF0F6E56),
      showYouAndCorrect: false,
      showOnlyCorrect: true,
    );
  }
  if (status == 'wrong') {
    return const _VerdictStatus(
      label: 'Incorrect',
      bg: Color(0xFFFCEBEB),
      pillBg: Color(0xFFF09595),
      pillText: Color(0xFF501313),
      anchorColor: Color(0xFF993C1D),
      showYouAndCorrect: true,
      showOnlyCorrect: false,
    );
  }
  if (status == 'correct') {
    return const _VerdictStatus(
      label: 'Correct',
      bg: Color(0xFFE1F5EE),
      pillBg: Color(0xFFC0DD97),
      pillText: Color(0xFF173404),
      anchorColor: Color(0xFF0F6E56),
      showYouAndCorrect: false,
      showOnlyCorrect: false,
    );
  }
  if (status == 'timed_out') {
    return const _VerdictStatus(
      label: "Time's up",
      bg: Color(0xFFFAEEDA),
      pillBg: Color(0xFFFAEEDA),
      pillText: Color(0xFF854F0B),
      anchorColor: Color(0xFF854F0B),
      showYouAndCorrect: false,
      showOnlyCorrect: true,
    );
  }
  return const _VerdictStatus(
    label: 'Skipped',
    bg: Color(0xFFFAEEDA),
    pillBg: Color(0xFFFAEEDA),
    pillText: Color(0xFF854F0B),
    anchorColor: Color(0xFF854F0B),
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

_OptionState _optionState(TestQuestion q, String letter, bool revisionMode) {
  final lower = letter.toLowerCase();
  final isCorrect = q.correctOption.toLowerCase() == lower;
  final isSelected = (q.selectedOption ?? '').toLowerCase() == lower;

  if (isCorrect) {
    return const _OptionState(
      bg: Color(0xFFEAF3DE),
      border: Color(0xFF97C459),
      letterColor: Color(0xFF3B6D11),
      textColor: Color(0xFF1A1A1A),
      strong: true,
      tag: 'Correct',
      tagBg: Color(0xFFC0DD97),
      tagColor: Color(0xFF173404),
    );
  }
  if (!revisionMode && q.status == 'wrong' && isSelected) {
    return const _OptionState(
      bg: Color(0xFFFCEBEB),
      border: Color(0xFFF09595),
      letterColor: Color(0xFFA32D2D),
      textColor: Color(0xFF1A1A1A),
      strong: true,
      tag: 'Your pick',
      tagBg: Color(0xFFF7C1C1),
      tagColor: Color(0xFF501313),
    );
  }
  final muted = revisionMode;
  return _OptionState(
    bg: Colors.white,
    border: Colors.black.withValues(alpha: 0.12),
    letterColor: const Color(0xFF888888),
    textColor: muted ? const Color(0xFF555555) : const Color(0xFF1A1A1A),
    strong: false,
  );
}
