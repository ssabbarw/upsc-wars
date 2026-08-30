import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:upsc_wars/core/analytics/activation_milestones.dart';
import 'package:upsc_wars/core/analytics/analytics_events.dart';
import 'package:upsc_wars/core/analytics/analytics_service.dart';
import 'package:upsc_wars/core/analytics/question_attempt_analytics_input.dart';
import 'package:upsc_wars/core/analytics/session_analytics_derive.dart';
import 'package:upsc_wars/core/constants/question_source_constants.dart';
import 'package:upsc_wars/core/database/user_db.dart';
import 'package:upsc_wars/features/history/data/repositories/session_history_repository_impl.dart';
import 'package:upsc_wars/features/home/domain/create_get_started_session_use_case.dart';
import 'package:upsc_wars/features/home/domain/daily_streak_service.dart';
import 'package:upsc_wars/features/home/domain/demo_diagnostic_ephemeral_store.dart';
import 'package:upsc_wars/core/domain/entities/active_session.dart';
import 'package:upsc_wars/core/domain/entities/answer_confidence.dart';
import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/core/domain/errors/app_errors.dart';
import 'package:upsc_wars/core/parsers/question_display_text_parser.dart';
import 'package:upsc_wars/core/providers/prefs_provider.dart';
import 'package:upsc_wars/core/services/local_daily_reminders_sync.dart';
import 'package:upsc_wars/core/services/no_test_reminder_service.dart';
import 'package:upsc_wars/core/services/question_stats_sync_service.dart';
import 'package:upsc_wars/features/test_engine/domain/repositories/test_engine_repository.dart';

class TestEngineRepositoryImpl implements TestEngineRepository {
  TestEngineRepositoryImpl({
    required UserDatabase userDb,
    required PrefsService prefsService,
    required AnalyticsService analytics,
  }) : _userDb = userDb,
       _prefsService = prefsService,
       _analytics = analytics;

  final UserDatabase _userDb;
  final PrefsService _prefsService;
  final AnalyticsService _analytics;

  static const _uuid = Uuid();

  @override
  Future<ActiveSession> loadSession(String sessionId) async {
    final ephemeral = DemoDiagnosticEphemeralStore.instance.peek(sessionId);
    if (ephemeral != null) return ephemeral.session;

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

    final questionRows = await _userDb.questionsDao.getByUuidsInOrder(
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
      questions.add(await _buildTestQuestionFromStoredRow(q, sq));
    }

    if (questions.isEmpty) {
      throw const SessionHasNoQuestionsException();
    }

    return ActiveSession(
      id: session.id,
      mode: session.mode,
      subject: session.subject,
      topic: session.topic,
      subTopic: session.subTopic,
      questionCount: session.questionCount,
      isTimed: session.isTimed,
      timeLimitSecs: session.timeLimitSecs,
      status: session.status,
      language: session.language,
      questions: questions,
      savedExamRemainingSecs: session.examRemainingSecs,
      analyticsFeatureKey: session.analyticsFeatureKey,
    );
  }

  @override
  Future<TestQuestion?> loadStandaloneQuestionByUuid(String uuid) async {
    final q = await _userDb.questionsDao.getByUuid(uuid);
    if (q == null) return null;
    final sq = SessionQuestion(
      id: 'standalone',
      sessionId: 'standalone',
      questionUuid: uuid,
      position: 1,
      selectedOption: null,
      isCorrect: null,
      status: 'unattempted',
      timeSpentSecs: null,
      flagged: false,
      attemptedAt: null,
      confidence: null,
    );
    return _buildTestQuestionFromStoredRow(q, sq);
  }

  Future<TestQuestion> _buildTestQuestionFromStoredRow(
    Question q,
    SessionQuestion sq,
  ) async {
    final trEn = await _userDb.questionTranslationsDao.getByQuestionAndLanguage(
      sq.questionUuid,
      'en',
    );
    final trHi = await _userDb.questionTranslationsDao.getByQuestionAndLanguage(
      sq.questionUuid,
      'hi',
    );
    if (trEn == null && trHi == null) {
      developer.log(
        'No translation for uuid=${sq.questionUuid}; falling back to question text',
        name: 'TestEngineRepository',
      );
    }

    final displayTextEn = q.enDisplayText ?? '';
    final displayTextHi = q.hiDisplayText ?? displayTextEn;
    final parsedEn = QuestionDisplayTextParser.parse(displayTextEn);
    final parsedHi = QuestionDisplayTextParser.parse(displayTextHi);
    final table = await _userDb.questionTablesDao.getByQuestionUuid(
      sq.questionUuid,
    );
    final footerEnOptions = _extractOptionsFromFooter(table?.enFooterText);
    final footerHiOptions = _extractOptionsFromFooter(table?.hiFooterText);

    String pickOption(
      String primary,
      String secondary,
      String? footerPrimary,
      String? footerSecondary,
      String fallback,
    ) {
      final p = primary.trim();
      if (p.isNotEmpty) return p;
      final s = secondary.trim();
      if (s.isNotEmpty) return s;
      final fp = (footerPrimary ?? '').trim();
      if (fp.isNotEmpty) return fp;
      final fs = (footerSecondary ?? '').trim();
      if (fs.isNotEmpty) return fs;
      return fallback;
    }

    final optionAEn = pickOption(
      parsedEn.optionA,
      parsedHi.optionA,
      footerEnOptions?.$1,
      footerHiOptions?.$1,
      'Option A',
    );
    final optionBEn = pickOption(
      parsedEn.optionB,
      parsedHi.optionB,
      footerEnOptions?.$2,
      footerHiOptions?.$2,
      'Option B',
    );
    final optionCEn = pickOption(
      parsedEn.optionC,
      parsedHi.optionC,
      footerEnOptions?.$3,
      footerHiOptions?.$3,
      'Option C',
    );
    final optionDEn = pickOption(
      parsedEn.optionD,
      parsedHi.optionD,
      footerEnOptions?.$4,
      footerHiOptions?.$4,
      'Option D',
    );
    final optionAHi = pickOption(
      parsedHi.optionA,
      parsedEn.optionA,
      footerHiOptions?.$1,
      footerEnOptions?.$1,
      optionAEn,
    );
    final optionBHi = pickOption(
      parsedHi.optionB,
      parsedEn.optionB,
      footerHiOptions?.$2,
      footerEnOptions?.$2,
      optionBEn,
    );
    final optionCHi = pickOption(
      parsedHi.optionC,
      parsedEn.optionC,
      footerHiOptions?.$3,
      footerEnOptions?.$3,
      optionCEn,
    );
    final optionDHi = pickOption(
      parsedHi.optionD,
      parsedEn.optionD,
      footerHiOptions?.$4,
      footerEnOptions?.$4,
      optionDEn,
    );

    return TestQuestion(
      uuid: q.uuid,
      subject: q.subject,
      topic: q.topic,
      negativeFraming: q.negativeFraming,
      displayText: parsedEn.stem.trim().isEmpty ? displayTextEn : parsedEn.stem,
      displayTextHi: parsedHi.stem.trim().isEmpty
          ? displayTextHi
          : parsedHi.stem,
      optionA: optionAEn,
      optionAHi: optionAHi,
      optionB: optionBEn,
      optionBHi: optionBHi,
      optionC: optionCEn,
      optionCHi: optionCHi,
      optionD: optionDEn,
      optionDHi: optionDHi,
      correctOption: q.correctOption,
      questionType: q.questionType,
      trapType: q.trapType,
      hasTable: q.hasTable,
      tableData: _parseTable(table, 'en'),
      tableDataHi: _parseTable(table, 'hi') ?? _parseTable(table, 'en'),
      position: sq.position,
      selectedOption: sq.selectedOption,
      status: sq.status,
      flagged: sq.flagged,
      timeSpentSecs: sq.timeSpentSecs,
      confidence: sq.confidence,
      conceptAnchor: q.conceptAnchor,
      finalExplanation: trEn?.finalExplanation ?? trHi?.finalExplanation,
      finalExplanationHi: trHi?.finalExplanation ?? trEn?.finalExplanation,
      eliminationLogic:
          _parseStringList(trEn?.eliminationLogic) + const <String>[],
      eliminationLogicHi: _parseStringList(
        trHi?.eliminationLogic ?? trEn?.eliminationLogic,
      ),
      statementAnalysis: _parseStatementAnalysis(trEn?.statementAnalysis),
      statementAnalysisHi: _parseStatementAnalysis(
        trHi?.statementAnalysis ?? trEn?.statementAnalysis,
      ),
      strongDistractor: trEn?.strongDistractor ?? trHi?.strongDistractor,
      strongDistractorHi: trHi?.strongDistractor ?? trEn?.strongDistractor,
      upscTrapExplanation:
          trEn?.upscTrapExplanation ?? trHi?.upscTrapExplanation,
      upscTrapExplanationHi:
          trHi?.upscTrapExplanation ?? trEn?.upscTrapExplanation,
      conceptsUsed: _parseStringList(q.conceptsUsed),
    );
  }

  @override
  Future<int> countScoredAttempts() =>
      _userDb.sessionQuestionsDao.countScoredAttempts();

  @override
  Future<Set<String>> fetchWeakTopicKeys(
    List<({String subject, String topic})> pairs,
  ) => _userDb.userTopicStatsDao.weakTopicKeysAmong(pairs);

  @override
  Future<bool> updateQuestionAttempt({
    required String sessionId,
    required String questionUuid,
    required String selectedOption,
    String? confidence,
    QuestionAttemptAnalyticsInput? analytics,
  }) async {
    final rows = await _userDb.sessionQuestionsDao.getSessionQuestionsOrdered(
      sessionId,
    );
    final sq = rows.where((e) => e.questionUuid == questionUuid).firstOrNull;
    if (sq == null) throw StateError('Question not in session');

    final q = await _userDb.questionsDao.getByUuid(questionUuid);
    if (q == null) throw StateError('Question missing in question db');

    final normSelected = selectedOption.toLowerCase();
    final isCorrect = q.correctOption.toLowerCase() == normSelected;
    final now = DateTime.now();
    final conf =
        confidence != null && AnswerConfidence.values.contains(confidence)
        ? confidence
        : null;
    await _userDb.sessionQuestionsDao.updateSessionQuestionFields(
      sq.id,
      selectedOption: Value(normSelected),
      isCorrect: Value(isCorrect),
      status: Value(isCorrect ? 'correct' : 'wrong'),
      attemptedAt: Value(now),
      confidence: conf != null ? Value(conf) : const Value.absent(),
    );

    if (analytics != null) {
      final sess = await _userDb.sessionsDao.getSessionById(sessionId);
      if (sess != null) {
        final labels = deriveSessionAnalyticsLabels(
          analyticsFeatureKey: sess.analyticsFeatureKey,
          subject: sess.subject,
        );
        await _analytics.track(
          QuestionAttemptedEvent(
            questionId: questionUuid,
            subject: q.subject,
            topic: q.topic,
            difficulty: null,
            correct: isCorrect,
            timeTakenSeconds: analytics.secondsOnQuestion,
            guessed: conf == AnswerConfidence.guessing,
            eliminatedOptionsCount: 0,
            trapType: q.trapType,
            confidenceLevel: AnswerConfidence.analyticsCode(conf),
            featureName: labels.featureName,
            source: labels.source,
          ),
        );
        if (conf != null) {
          await _trackConfidenceMarked(
            sessionId: sessionId,
            confidence: conf,
            markingSource: 'pre_reveal_prompt',
          );
        }
      }
    }

    final prevStreak = _prefsService.currentStreak;
    DailyStreakService.recordRingClosed(prefs: _prefsService);
    final nextStreak = _prefsService.currentStreak;
    if (nextStreak > prevStreak) {
      await _analytics.track(StreakContinuedEvent(streakLength: nextStreak));
    }
    return isCorrect;
  }

  @override
  Future<void> updateAttemptConfidenceOnly({
    required String sessionId,
    required String questionUuid,
    String? confidence,
  }) async {
    final rows = await _userDb.sessionQuestionsDao.getSessionQuestionsOrdered(
      sessionId,
    );
    final sq = rows.where((e) => e.questionUuid == questionUuid).firstOrNull;
    if (sq == null) return;
    final conf =
        confidence != null && AnswerConfidence.values.contains(confidence)
        ? confidence
        : null;
    await _userDb.sessionQuestionsDao.updateSessionQuestionFields(
      sq.id,
      confidence: Value(conf),
    );
    if (conf != null) {
      await _trackConfidenceMarked(
        sessionId: sessionId,
        confidence: conf,
        markingSource: 'option_strip',
      );
    }
  }

  Future<void> _trackConfidenceMarked({
    required String sessionId,
    required String confidence,
    required String markingSource,
  }) async {
    final level = AnswerConfidence.analyticsCode(confidence);
    if (level == null) return;
    final sess = await _userDb.sessionsDao.getSessionById(sessionId);
    if (sess == null) return;
    final labels = deriveSessionAnalyticsLabels(
      analyticsFeatureKey: sess.analyticsFeatureKey,
      subject: sess.subject,
    );
    await _analytics.track(
      ConfidenceMarkedEvent(
        confidenceLevel: level,
        sessionMode: sess.mode,
        markingSource: markingSource,
        featureName: labels.featureName,
        source: labels.source,
      ),
    );
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
    final sessionMeta = await _userDb.sessionsDao.getSessionById(sessionId);

    final rows = await _userDb.sessionQuestionsDao.getSessionQuestionsOrdered(
      sessionId,
    );
    for (final row in rows.where((e) => e.status == 'wrong')) {
      await _userDb.revisionQueueDao.add(
        id: _uuid.v4(),
        questionUuid: row.questionUuid,
        dateAddedToQueue: DateTime.now(),
      );
      await _userDb.revisionQueueDao.updateCounts(
        questionUuid: row.questionUuid,
        answeredCorrectly: false,
      );
    }

    await _userDb.sessionsDao.updateExamRemainingSecs(sessionId, null);

    await _userDb.sessionsDao.updateSessionStatus(sessionId, 'completed');
    await _userDb.sessionsDao.updateSessionCompletedAt(
      sessionId,
      DateTime.now(),
    );
    unawaited(
      QuestionStatsSyncService(
        userDb: _userDb,
      ).persistAndSyncSession(sessionId),
    );
    final completedSessionCount = await _userDb.sessionsDao
        .countCompletedSessions();
    if (completedSessionCount == 1) {
      await _analytics.track(const FirstSessionCompletedEvent());
      await NoTestReminderService.cancelAfterFirstTest();
    }
    await logFirstTestDoneForServices(_analytics, _prefsService);

    await _recordHomeActivation(sessionId, sessionMeta?.analyticsFeatureKey);

    unawaited(
      LocalDailyRemindersSync.syncPractice(
        prefs: _prefsService,
        db: _userDb,
        dailyCaEnabled: true,
      ),
    );

    await _updateTopicStatsForSession(sessionId);

    final prevStreak = _prefsService.currentStreak;
    _updateStreak();
    final nextStreak = _prefsService.currentStreak;
    if (nextStreak > prevStreak) {
      await _analytics.track(StreakContinuedEvent(streakLength: nextStreak));
    }

    if (sessionMeta != null) {
      final labels = deriveSessionAnalyticsLabels(
        analyticsFeatureKey: sessionMeta.analyticsFeatureKey,
        subject: sessionMeta.subject,
      );
      await _analytics.track(
        FeatureCompletedEvent(
          featureName: labels.featureName,
          subject: sessionMeta.subject,
          topic: sessionMeta.topic,
          difficulty: null,
          source: labels.source,
        ),
      );
      if (sessionMeta.subject == 'revision' ||
          sessionMeta.subject == 'revision_quick') {
        await _analytics.track(
          RevisionCompletedEvent(
            questionsCount: sessionMeta.questionCount,
            subject: sessionMeta.subject,
          ),
        );
      }
    }

    try {
      final r = await SessionHistoryRepositoryImpl(
        _userDb,
      ).getSessionResult(sessionId);
      final accH = (r.accuracy * 100).round();
      await _analytics.track(
        UspSessionResultSnapshotEvent(
          featureKey: r.analyticsFeatureKey ?? 'unknown',
          subject: r.subject,
          questionCount: r.questionCount,
          correct: r.correct,
          wrong: r.wrong,
          accuracyHundredths: accH,
          dangerZoneWrongCount: r.dangerZoneWrongCount,
          sureTotal: r.confidenceSureTotal,
          sureCorrect: r.confidenceSureCorrect,
          intelligentTotal: r.confidenceIntelligentTotal,
          intelligentCorrect: r.confidenceIntelligentCorrect,
          pureTotal: r.confidencePureTotal,
          pureCorrect: r.confidencePureCorrect,
        ),
      );
      final caKey = r.analyticsFeatureKey;
      final dateId = r.topic ?? sessionMeta?.topic;
      if (dateId != null &&
          dateId.isNotEmpty &&
          (caKey == QuestionSourceConstants.analyticsDailyCurrentAffairs ||
              caKey ==
                  QuestionSourceConstants.analyticsDailyCurrentAffairsRevise)) {
        await _analytics.track(
          DailyCaSubmittedEvent(
            dateId: dateId,
            mode: caKey ==
                    QuestionSourceConstants.analyticsDailyCurrentAffairsRevise
                ? 'revise'
                : 'first',
            score: r.accuracy,
          ),
        );
      }
    } catch (e, st) {
      developer.log(
        'UspSessionResultSnapshot skipped: $e',
        name: 'TestEngineRepositoryImpl',
        error: e,
        stackTrace: st,
      );
    }

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
    await logFirstTestQuitInMidForServices(_analytics, _prefsService);
    final sessionMeta = await _userDb.sessionsDao.getSessionById(sessionId);
    await _userDb.sessionsDao.updateSessionStatus(sessionId, 'abandoned');
    if (sessionMeta != null) {
      final labels = deriveSessionAnalyticsLabels(
        analyticsFeatureKey: sessionMeta.analyticsFeatureKey,
        subject: sessionMeta.subject,
      );
      await _analytics.track(
        TestSessionAbandonedEvent(
          featureName: labels.featureName,
          subject: sessionMeta.subject,
          topic: sessionMeta.topic,
          source: labels.source,
        ),
      );
    }
  }

  @override
  Future<void> discardSession(
    String sessionId, {
    bool userInitiatedQuit = false,
  }) async {
    if (userInitiatedQuit) {
      await logFirstTestQuitInMidForServices(_analytics, _prefsService);
    }
    await _userDb.transaction(() async {
      await (_userDb.delete(
        _userDb.sessionQuestions,
      )..where((t) => t.sessionId.equals(sessionId))).go();
      await (_userDb.delete(
        _userDb.sessions,
      )..where((t) => t.id.equals(sessionId))).go();
    });
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
      unawaited(
        QuestionStatsSyncService(userDb: _userDb).recordBookmark(questionUuid),
      );
    }
    await _userDb.revisionQueueDao.add(
      id: _uuid.v4(),
      questionUuid: questionUuid,
      dateAddedToQueue: DateTime.now(),
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
    DailyStreakService.recordRingClosed(prefs: _prefsService);
  }

  Future<void> _updateTopicStatsForSession(String sessionId) async {
    final session = await _userDb.sessionsDao.getSessionById(sessionId);
    if (session == null) return;
    final rows = await _userDb.sessionQuestionsDao.getSessionQuestionsOrdered(
      sessionId,
    );
    final scored = rows
        .where((r) => r.status == 'correct' || r.status == 'wrong')
        .toList();
    if (scored.isEmpty) return;

    final questions = await _userDb.questionsDao.getByUuidsInOrder(
      scored.map((e) => e.questionUuid).toList(),
    );
    final byUuid = {for (final q in questions) q.uuid: q};
    final agg =
        <String, ({int attempted, int correct, int wrong, int timeSum})>{};
    for (final row in scored) {
      final q = byUuid[row.questionUuid];
      if (q == null) continue;
      final key = '${q.subject}||${q.topic}';
      final prev = agg[key];
      final attempted = (prev?.attempted ?? 0) + 1;
      final correct = (prev?.correct ?? 0) + (row.status == 'correct' ? 1 : 0);
      final wrong = (prev?.wrong ?? 0) + (row.status == 'wrong' ? 1 : 0);
      final timeSum = (prev?.timeSum ?? 0) + (row.timeSpentSecs ?? 0);
      agg[key] = (
        attempted: attempted,
        correct: correct,
        wrong: wrong,
        timeSum: timeSum,
      );
    }

    final now = DateTime.now();
    for (final entry in agg.entries) {
      final parts = entry.key.split('||');
      await _userDb.userTopicStatsDao.upsertAfterSessionCompletion(
        subject: parts[0],
        topic: parts[1],
        attemptedToAdd: entry.value.attempted,
        correctToAdd: entry.value.correct,
        wrongToAdd: entry.value.wrong,
        timeSpentSecsSum: entry.value.timeSum,
        attemptedAt: now,
      );
    }
  }

  QuestionTableData? _parseTable(QuestionTable? table, String language) {
    if (table == null) return null;
    final columnsRaw = language == 'hi' ? table.hiColumns : table.enColumns;
    final rowsRaw = language == 'hi' ? table.hiRows : table.enRows;
    final header = language == 'hi' ? table.hiHeaderText : table.enHeaderText;
    final footerRaw = language == 'hi'
        ? table.hiFooterText
        : table.enFooterText;
    final footer = _stripOptionsFromFooter(footerRaw);
    final columns = _parseStringList(columnsRaw);
    final rowsDecoded = _safeJsonDecode(rowsRaw);
    if (columns.isEmpty || rowsDecoded is! List) return null;
    final rows = questionTableRowsAsCells(rowsDecoded, columns);
    return QuestionTableData(
      header: header,
      footer: footer,
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

  (String, String, String, String)? _extractOptionsFromFooter(String? footer) {
    if (footer == null || footer.trim().isEmpty) return null;
    final parsed = QuestionDisplayTextParser.parse(footer);
    final a = parsed.optionA.trim();
    final b = parsed.optionB.trim();
    final c = parsed.optionC.trim();
    final d = parsed.optionD.trim();
    if (a.isEmpty || b.isEmpty || c.isEmpty || d.isEmpty) return null;
    return (a, b, c, d);
  }

  String? _stripOptionsFromFooter(String? footer) {
    if (footer == null || footer.trim().isEmpty) return footer;
    final parsed = QuestionDisplayTextParser.parse(footer);
    final hasAllOptions =
        parsed.optionA.trim().isNotEmpty &&
        parsed.optionB.trim().isNotEmpty &&
        parsed.optionC.trim().isNotEmpty &&
        parsed.optionD.trim().isNotEmpty;
    if (!hasAllOptions) return footer;
    final stem = parsed.stem.trim();
    return stem.isEmpty ? null : stem;
  }

  Future<void> _recordHomeActivation(
    String sessionId,
    String? analyticsFeatureKey,
  ) async {
    final now = DateTime.now();
    final dayKey = DateFormat('yyyy-MM-dd').format(now);
    _prefsService.appendActivationSessionDay(dayKey);

    // Activation funnel: distinct active study days. north-star = 2nd day.
    final distinctDays = _prefsService.activationSessionDays.length;
    if (distinctDays >= 2) {
      await logActivationMilestoneForServices(
        _analytics,
        _prefsService,
        id: ActivationMilestones.activatedSecondDay,
      );
    }
    if (distinctDays >= 3) {
      await logActivationMilestoneForServices(
        _analytics,
        _prefsService,
        id: ActivationMilestones.habituatedThreeDays,
      );
    }

    final rows = await _userDb.sessionQuestionsDao.getSessionQuestionsOrdered(
      sessionId,
    );
    final hasSureOrEdu = rows.any(
      (r) =>
          (r.status == 'correct' || r.status == 'wrong') &&
          AnswerConfidence.isDangerouslyConfident(r.confidence),
    );
    if (hasSureOrEdu) {
      markHomeActivationComplete(_prefsService);
      unawaited(
        LocalDailyRemindersSync.syncPractice(
          prefs: _prefsService,
          db: _userDb,
          dailyCaEnabled: true,
        ),
      );
    }

    if (analyticsFeatureKey == CreateGetStartedSessionUseCase.analyticsKey) {
      _prefsService.getStartedDiagnosticAttempted = true;
      await logActivationMilestoneForServices(
        _analytics,
        _prefsService,
        id: ActivationMilestones.getStartedDiagnosticCompleted,
      );
    }
  }
}
