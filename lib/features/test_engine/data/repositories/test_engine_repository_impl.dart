import 'dart:convert';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:upsc_wars/core/database/question_db.dart';
import 'package:upsc_wars/core/database/user_db.dart';
import 'package:upsc_wars/core/domain/entities/active_session.dart';
import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/core/domain/errors/app_errors.dart';
import 'package:upsc_wars/core/parsers/question_display_text_parser.dart';
import 'package:upsc_wars/core/providers/prefs_provider.dart';
import 'package:upsc_wars/features/test_engine/domain/repositories/test_engine_repository.dart';

class TestEngineRepositoryImpl implements TestEngineRepository {
  TestEngineRepositoryImpl({
    required UserDatabase userDb,
    required QuestionDb questionDb,
    required PrefsService prefsService,
  }) : _userDb = userDb,
       _questionDb = questionDb,
       _prefsService = prefsService;

  final UserDatabase _userDb;
  final QuestionDb _questionDb;
  final PrefsService _prefsService;

  static const _uuid = Uuid();

  @override
  Future<ActiveSession> loadSession(String sessionId) async {
    final session = await _userDb.sessionsDao.getSessionById(sessionId);
    if (session == null) {
      throw const SessionNotFoundException();
    }

    final sqs = await _userDb.sessionQuestionsDao.getSessionQuestionsOrdered(
      sessionId,
    );
    if (sqs.isEmpty) {
      throw const SessionHasNoQuestionsException();
    }

    final questionRows = await _questionDb.getQuestionsByUuids(
      sqs.map((e) => e.questionUuid).toList(),
    );
    final byUuid = {for (final q in questionRows) q.uuid: q};

    final questions = <TestQuestion>[];
    for (final sq in sqs) {
      final q = byUuid[sq.questionUuid];
      if (q == null) {
        developer.log(
          'Question row missing in question DB for uuid=${sq.questionUuid}',
          name: 'TestEngineRepository',
        );
        continue;
      }
      final tr =
          await _questionDb.getQuestionTranslation(
            sq.questionUuid,
            session.language,
          ) ??
          await _questionDb.getQuestionTranslation(sq.questionUuid, 'en');
      if (tr == null) {
        developer.log(
          'No translation for uuid=${sq.questionUuid} lang=${session.language}',
          name: 'TestEngineRepository',
        );
        continue;
      }

      final parsed = QuestionDisplayTextParser.parse(tr.displayText);
      final oa = parsed.optionA.trim();
      final ob = parsed.optionB.trim();
      final oc = parsed.optionC.trim();
      final od = parsed.optionD.trim();
      if (oa.isEmpty || ob.isEmpty || oc.isEmpty || od.isEmpty) {
        developer.log(
          'Skipping question with empty options uuid=${sq.questionUuid}',
          name: 'TestEngineRepository',
        );
        continue;
      }

      questions.add(
        TestQuestion(
          uuid: q.uuid,
          displayText:
              parsed.stem.trim().isEmpty ? tr.displayText : parsed.stem,
          optionA: oa,
          optionB: ob,
          optionC: oc,
          optionD: od,
          correctOption: q.correctOption,
          questionType: q.questionType,
          trapType: q.trapType,
          hasTable: q.hasTable,
          tableData: _parseTable(tr),
          position: sq.position,
          selectedOption: sq.selectedOption,
          status: sq.status,
          flagged: sq.flagged,
          timeSpentSecs: sq.timeSpentSecs,
          conceptAnchor: tr.conceptAnchor,
          finalExplanation: tr.finalExplanation,
          eliminationLogic: _parseStringList(tr.eliminationLogic),
          statementAnalysis: _parseStatementAnalysis(tr.statementAnalysis),
          strongDistractor: tr.strongDistractor,
          upscTrapExplanation: tr.upscTrapExplanation,
          conceptsUsed: _parseStringList(tr.conceptsUsed),
        ),
      );
    }

    if (questions.isEmpty) {
      throw const SessionHasNoQuestionsException();
    }

    return ActiveSession(
      id: session.id,
      mode: session.mode,
      subjectSlug: session.subjectSlug,
      topicSlug: session.topicSlug,
      subTopicSlug: session.subTopicSlug,
      questionCount: session.questionCount,
      isTimed: session.isTimed,
      timeLimitSecs: session.timeLimitSecs,
      status: session.status,
      language: session.language,
      questions: questions,
      savedExamRemainingSecs: session.examRemainingSecs,
    );
  }

  @override
  Future<bool> updateQuestionAttempt({
    required String sessionId,
    required String questionUuid,
    required String selectedOption,
  }) async {
    final rows = await _userDb.sessionQuestionsDao.getSessionQuestionsOrdered(
      sessionId,
    );
    final sq = rows.where((e) => e.questionUuid == questionUuid).firstOrNull;
    if (sq == null) throw StateError('Question not in session');

    final q =
        (await _questionDb.getQuestionsByUuids([questionUuid])).firstOrNull;
    if (q == null) throw StateError('Question missing in question db');

    final normSelected = selectedOption.toLowerCase();
    final isCorrect = q.correctOption.toLowerCase() == normSelected;
    await _userDb.sessionQuestionsDao.updateSessionQuestionFields(
      sq.id,
      selectedOption: Value(normSelected),
      isCorrect: Value(isCorrect),
      status: Value(isCorrect ? 'correct' : 'wrong'),
    );
    return isCorrect;
  }

  @override
  Future<void> updateQuestionTime({
    required String sessionId,
    required String questionUuid,
    required int timeSpentSecs,
  }) async {
    final rows = await _userDb.sessionQuestionsDao.getSessionQuestionsOrdered(
      sessionId,
    );
    final sq = rows.where((e) => e.questionUuid == questionUuid).firstOrNull;
    if (sq == null) return;
    await _userDb.sessionQuestionsDao.updateSessionQuestionFields(
      sq.id,
      timeSpentSecs: Value(timeSpentSecs),
    );
  }

  @override
  Future<void> flagQuestion({
    required String sessionId,
    required String questionUuid,
    required bool flagged,
  }) async {
    final rows = await _userDb.sessionQuestionsDao.getSessionQuestionsOrdered(
      sessionId,
    );
    final sq = rows.where((e) => e.questionUuid == questionUuid).firstOrNull;
    if (sq == null) return;
    await _userDb.sessionQuestionsDao.updateFlagged(sq.id, flagged);
  }

  @override
  Future<String> submitSession(String sessionId) async {
    final rows = await _userDb.sessionQuestionsDao.getSessionQuestionsOrdered(
      sessionId,
    );
    for (final row in rows.where((e) => e.status == 'wrong')) {
      await _userDb.revisionQueueDao.insertOrUpdateRevisionItem(
        id: _uuid.v4(),
        questionUuid: row.questionUuid,
        addedAt: DateTime.now(),
        reason: 'wrong',
      );
    }

    await _userDb.sessionsDao.updateExamRemainingSecs(sessionId, null);

    await _userDb.sessionsDao.updateSessionStatus(sessionId, 'completed');
    await _userDb.sessionsDao.updateSessionCompletedAt(
      sessionId,
      DateTime.now(),
    );

    _updateStreak();

    return sessionId;
  }

  @override
  Future<void> handleTimedOutQuestion({
    required String sessionId,
    required String questionUuid,
  }) async {
    final rows = await _userDb.sessionQuestionsDao.getSessionQuestionsOrdered(
      sessionId,
    );
    final sq = rows.where((e) => e.questionUuid == questionUuid).firstOrNull;
    if (sq == null) return;
    await _userDb.sessionQuestionsDao.updateSessionQuestionFields(
      sq.id,
      status: const Value('timed_out'),
      isCorrect: const Value(null),
    );
  }

  @override
  Future<void> markSessionAbandoned(String sessionId) async {
    await _userDb.sessionsDao.updateSessionStatus(sessionId, 'abandoned');
  }

  @override
  Future<bool> isBookmarked(String questionUuid) =>
      _userDb.bookmarksDao.isQuestionBookmarked(questionUuid);

  @override
  Future<void> addBookmark(String questionUuid) async {
    final existing = await _userDb.bookmarksDao.getBookmarkByQuestionUuid(
      questionUuid,
    );
    if (existing == null) {
      await _userDb.bookmarksDao.insertBookmark(
        BookmarksCompanion.insert(
          id: _uuid.v4(),
          questionUuid: questionUuid,
          createdAt: DateTime.now(),
        ),
      );
    }
    await _userDb.revisionQueueDao.insertOrUpdateRevisionItem(
      id: _uuid.v4(),
      questionUuid: questionUuid,
      addedAt: DateTime.now(),
      reason: 'bookmarked',
    );
  }

  @override
  Future<void> removeBookmark(String questionUuid) async {
    await _userDb.bookmarksDao.deleteBookmarkByQuestionUuid(questionUuid);
  }

  @override
  Future<void> saveExamRemainingSeconds({
    required String sessionId,
    required int remainingSecs,
  }) async {
    await _userDb.sessionsDao.updateExamRemainingSecs(
      sessionId,
      remainingSecs.clamp(0, 1 << 30),
    );
  }

  void _updateStreak() {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final yesterday = DateFormat(
      'yyyy-MM-dd',
    ).format(now.subtract(const Duration(days: 1)));
    final last = _prefsService.lastActiveDate;
    final current = _prefsService.currentStreak;

    var next = 1;
    if (last == today) {
      next = current == 0 ? 1 : current;
    } else if (last == yesterday) {
      next = current + 1;
    }

    _prefsService.currentStreak = next;
    _prefsService.lastActiveDate = today;
    if (next > _prefsService.longestStreak) {
      _prefsService.longestStreak = next;
    }
  }

  QuestionTableData? _parseTable(QuestionTranslationRow tr) {
    if (tr.columns == null || tr.rows == null) return null;
    final columns = _parseStringList(tr.columns);
    final rowsDecoded = _safeJsonDecode(tr.rows!);
    if (columns.isEmpty || rowsDecoded is! List) return null;
    final rows = <List<String>>[];
    for (final row in rowsDecoded) {
      if (row is List) {
        rows.add(row.map((e) => e?.toString() ?? '').toList());
      }
    }
    return QuestionTableData(
      header: tr.headerText,
      footer: tr.footerText,
      columns: columns,
      rows: rows,
    );
  }

  List<String> _parseStringList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    final parsed = _safeJsonDecode(raw);
    if (parsed is List) {
      return parsed
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  List<StatementAnalysisItem> _parseStatementAnalysis(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    final parsed = _safeJsonDecode(raw);
    if (parsed is! List) return const [];

    final out = <StatementAnalysisItem>[];
    for (final item in parsed) {
      if (item is Map) {
        final label = (item['statement'] ?? item['label'] ?? '').toString();
        final reason = (item['reason'] ?? item['explanation'] ?? '').toString();
        final verdict =
            (item['is_correct'] ?? item['correct'] ?? false) == true;
        if (label.isNotEmpty || reason.isNotEmpty) {
          out.add(
            StatementAnalysisItem(
              label: label,
              isCorrect: verdict,
              reason: reason,
            ),
          );
        }
      }
    }
    return out;
  }

  Object? _safeJsonDecode(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }
}
