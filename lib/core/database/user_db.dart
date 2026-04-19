import 'package:drift/drift.dart';

import 'user_db_connection_io.dart' if (dart.library.html) 'user_db_connection_web.dart'
    as user_db_connection;

part 'user_db.g.dart';

class Questions extends Table {
  TextColumn get uuid => text()();
  TextColumn get subject => text()();
  TextColumn get topic => text()();
  TextColumn get subTopic => text().named('sub_topic')();
  TextColumn get questionType => text().named('question_type')();
  TextColumn get trapType => text().named('trap_type').nullable()();
  TextColumn get correctOption => text().named('correct_option')();
  TextColumn get conceptAnchor => text().named('concept_anchor')();
  TextColumn get conceptsUsed => text().named('concepts_used')();
  TextColumn get enDisplayText => text().named('en_display_text').nullable()();
  TextColumn get hiDisplayText => text().named('hi_display_text').nullable()();
  BoolColumn get hasTable =>
      boolean().named('has_table').withDefault(const Constant(false))();
  BoolColumn get negativeFraming =>
      boolean().named('negative_framing').withDefault(const Constant(false))();
  /// 1-based position within a PYQ year paper; null for non-PYQ questions.
  IntColumn get paperOrder => integer().named('paper_order').nullable()();

  @override
  Set<Column> get primaryKey => {uuid};
}

class QuestionTranslations extends Table {
  @override
  String get tableName => 'explanations';

  TextColumn get questionUuid =>
      text().named('question_uuid').references(Questions, #uuid)();
  TextColumn get language => text()();
  TextColumn get strongDistractor => text().named('strong_distractor')();
  TextColumn get eliminationLogic => text().named('elimination_logic')();
  TextColumn get upscTrapExplanation => text().named('upsc_trap_explanation')();
  TextColumn get finalExplanation => text().named('final_explanation')();
  TextColumn get statementAnalysis =>
      text().named('statement_analysis').nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {questionUuid, language},
  ];
}

class QuestionTables extends Table {
  @override
  String get tableName => 'question_tables';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get questionUuid =>
      text().named('question_uuid').references(Questions, #uuid)();
  TextColumn get enHeaderText => text().named('en_header_text').nullable()();
  TextColumn get enFooterText => text().named('en_footer_text').nullable()();
  TextColumn get enColumns => text().named('en_columns')();
  TextColumn get enRows => text().named('en_rows')();
  TextColumn get hiHeaderText => text().named('hi_header_text').nullable()();
  TextColumn get hiFooterText => text().named('hi_footer_text').nullable()();
  TextColumn get hiColumns => text().named('hi_columns')();
  TextColumn get hiRows => text().named('hi_rows')();

  @override
  List<Set<Column>> get uniqueKeys => [
    {questionUuid},
  ];
}

class TopicTranslations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get englishName => text().named('english_name')();
  TextColumn get hindiName => text().named('hindi_name')();
}

class Sessions extends Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get subject => text()();
  TextColumn get topic => text().nullable()();
  TextColumn get subTopic => text().named('sub_topic').nullable()();
  TextColumn get mode => text()();
  TextColumn get status => text()();
  IntColumn get questionCount => integer()();
  IntColumn get score => integer().nullable()();
  BoolColumn get isTimed => boolean()();
  IntColumn get timeLimitSecs => integer().nullable()();
  IntColumn get examRemainingSecs => integer().nullable()();
  TextColumn get language => text().withDefault(const Constant('en'))();
  TextColumn get analyticsFeatureKey =>
      text().named('analytics_feature_key').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SessionQuestions extends Table {
  @override
  String get tableName => 'attempts';

  TextColumn get id => text()();
  TextColumn get sessionId => text().references(Sessions, #id)();
  TextColumn get questionUuid =>
      text().named('question_uuid').references(Questions, #uuid)();
  IntColumn get position => integer()();
  TextColumn get selectedOption => text().nullable()();
  BoolColumn get isCorrect => boolean().nullable()();
  TextColumn get status => text().withDefault(const Constant('unattempted'))();
  IntColumn get timeSpentSecs => integer().nullable()();
  BoolColumn get flagged => boolean().withDefault(const Constant(false))();
  DateTimeColumn get attemptedAt => dateTime().nullable()();
  /// `very_sure` | `somewhat_sure` | `guessing`; null = not captured / ignored.
  TextColumn get confidence => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Bookmarks extends Table {
  TextColumn get id => text()();
  TextColumn get questionUuid =>
      text().named('question_uuid').unique().references(Questions, #uuid)();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get userNote => text().named('user_note').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class RevisionQueue extends Table {
  TextColumn get id => text()();
  TextColumn get questionUuid =>
      text().named('question_uuid').unique().references(Questions, #uuid)();
  DateTimeColumn get dateAddedToQueue => dateTime().named('date_added_to_queue')();
  IntColumn get numberOfTimesAnsweredCorrectlyInRevision => integer()
      .named('number_of_times_answered_correctly_in_revision')
      .withDefault(const Constant(0))();
  IntColumn get numberOfTimesAnsweredIncorrectlyInRevision => integer()
      .named('number_of_times_answered_incorrectly_in_revision')
      .withDefault(const Constant(0))();
  BoolColumn get hasGraduatedFromQueue =>
      boolean().named('has_graduated_from_queue').withDefault(const Constant(false))();
  DateTimeColumn get dateGraduated => dateTime().named('date_graduated').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class UserTopicStats extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get subject => text()();
  TextColumn get topic => text()();
  IntColumn get totalAttempted =>
      integer().named('total_attempted').withDefault(const Constant(0))();
  IntColumn get totalCorrect =>
      integer().named('total_correct').withDefault(const Constant(0))();
  IntColumn get wrongAttempts =>
      integer().named('wrong_attempts').withDefault(const Constant(0))();
  IntColumn get totalTimeSpentSecs =>
      integer().named('total_time_spent_secs').withDefault(const Constant(0))();
  RealColumn get accuracyPercentage =>
      real().named('accuracy_percentage').withDefault(const Constant(0.0))();
  DateTimeColumn get lastAttemptedAt =>
      dateTime().named('last_attempted_at')();

  @override
  List<Set<Column>> get uniqueKeys => [
    {subject, topic},
  ];
}

class UserFeatureStats extends Table {
  TextColumn get featureName => text().named('feature_name')();
  IntColumn get totalViews =>
      integer().named('total_views').withDefault(const Constant(0))();
  IntColumn get totalStarts =>
      integer().named('total_starts').withDefault(const Constant(0))();
  IntColumn get totalCompletions =>
      integer().named('total_completions').withDefault(const Constant(0))();
  DateTimeColumn get lastUsedAt => dateTime().named('last_used_at')();

  @override
  Set<Column> get primaryKey => {featureName};
}

class UserTrapStats extends Table {
  TextColumn get trapType => text().named('trap_type')();
  IntColumn get totalFailures =>
      integer().named('total_failures').withDefault(const Constant(0))();
  DateTimeColumn get lastFailedAt => dateTime().named('last_failed_at')();

  @override
  Set<Column> get primaryKey => {trapType};
}

@DriftAccessor(tables: [Questions])
class QuestionsDao extends DatabaseAccessor<UserDatabase> with _$QuestionsDaoMixin {
  QuestionsDao(super.db);

  Future<Question?> getByUuid(String uuid) =>
      (select(questions)..where((t) => t.uuid.equals(uuid))).getSingleOrNull();

  Future<List<Question>> getBySubject(String subject) =>
      (select(questions)
            ..where((t) => t.subject.equals(subject))
            ..orderBy([(t) => OrderingTerm.asc(t.uuid)]))
          .get();

  /// PYQ and other ordered sets: paper order first, then uuid (null paper_order last).
  Future<List<Question>> getBySubjectPaperOrder(String subject) async {
    final rows = await customSelect(
      'SELECT * FROM questions WHERE subject = ? '
      'ORDER BY paper_order IS NULL, paper_order ASC, uuid ASC',
      variables: [Variable.withString(subject)],
      readsFrom: {questions},
    ).get();
    return rows.map((r) => questions.map(r.data)).toList();
  }

  Future<List<Question>> getByTopic(String subject, String topic) =>
      (select(questions)
            ..where((t) => t.subject.equals(subject) & t.topic.equals(topic))
            ..orderBy([(t) => OrderingTerm.asc(t.uuid)]))
          .get();

  Future<List<Question>> getUnseenFirstBySubject({
    required String subject,
    required int limit,
    required Set<String> attemptedQuestionUuids,
  }) async {
    if (limit <= 0) return const [];
    final unseenUuids = await _randomQuestionUuids(
      subject: subject,
      limit: limit,
      attemptedQuestionUuids: attemptedQuestionUuids,
      preferUnseen: true,
    );
    if (unseenUuids.length >= limit) {
      return getByUuidsInOrder(unseenUuids.take(limit).toList());
    }
    final seenUuids = await _randomQuestionUuids(
      subject: subject,
      limit: limit - unseenUuids.length,
      attemptedQuestionUuids: attemptedQuestionUuids,
      preferUnseen: false,
    );
    return getByUuidsInOrder([...unseenUuids, ...seenUuids]);
  }

  Future<List<Question>> getUnseenFirstByTopic({
    required String subject,
    required String topic,
    required int limit,
    required Set<String> attemptedQuestionUuids,
  }) async {
    if (limit <= 0) return const [];
    final unseenUuids = await _randomQuestionUuids(
      subject: subject,
      topic: topic,
      limit: limit,
      attemptedQuestionUuids: attemptedQuestionUuids,
      preferUnseen: true,
    );
    if (unseenUuids.length >= limit) {
      return getByUuidsInOrder(unseenUuids.take(limit).toList());
    }
    final seenUuids = await _randomQuestionUuids(
      subject: subject,
      topic: topic,
      limit: limit - unseenUuids.length,
      attemptedQuestionUuids: attemptedQuestionUuids,
      preferUnseen: false,
    );
    return getByUuidsInOrder([...unseenUuids, ...seenUuids]);
  }

  /// Random MCQs from the whole bank (any subject), unseen-first then seen.
  Future<List<Question>> getUnseenFirstRandomMixed({
    required int limit,
    required Set<String> attemptedQuestionUuids,
  }) async {
    if (limit <= 0) return const [];
    final unseenUuids = await _randomQuestionUuidsMixed(
      limit: limit,
      attemptedQuestionUuids: attemptedQuestionUuids,
      preferUnseen: true,
    );
    if (unseenUuids.length >= limit) {
      return getByUuidsInOrder(unseenUuids.take(limit).toList());
    }
    final seenUuids = await _randomQuestionUuidsMixed(
      limit: limit - unseenUuids.length,
      attemptedQuestionUuids: attemptedQuestionUuids,
      preferUnseen: false,
    );
    return getByUuidsInOrder([...unseenUuids, ...seenUuids]);
  }

  Future<List<SubjectQuestionCount>> getSubjectQuestionCounts() async {
    return customSelect(
      'SELECT subject, COUNT(*) AS c FROM questions GROUP BY subject ORDER BY subject ASC',
      readsFrom: {questions},
    ).map((row) {
      return SubjectQuestionCount(
        subject: row.read<String>('subject'),
        questionCount: row.read<int>('c'),
      );
    }).get();
  }

  Future<int> getTotalQuestionCount() async {
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM questions',
      readsFrom: {questions},
    ).getSingle();
    return row.read<int>('c');
  }

  Future<int> getQuestionCountBySubject(String subject) async {
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM questions WHERE subject = ?',
      variables: [Variable.withString(subject)],
      readsFrom: {questions},
    ).getSingle();
    return row.read<int>('c');
  }

  Future<List<TopicQuestionCount>> getTopicQuestionCountsForSubject(String subject) async {
    return customSelect(
      'SELECT topic, COUNT(*) AS c FROM questions WHERE subject = ? GROUP BY topic ORDER BY topic ASC',
      variables: [Variable.withString(subject)],
      readsFrom: {questions},
    ).map((row) {
      return TopicQuestionCount(
        topic: row.read<String>('topic'),
        questionCount: row.read<int>('c'),
      );
    }).get();
  }

  Future<Map<String, QuestionSubjectTopic>> getSubjectTopicForUuids(
    List<String> uuids,
  ) async {
    final result = <String, QuestionSubjectTopic>{};
    final rows = await getByUuidsInOrder(uuids);
    for (final row in rows) {
      result[row.uuid] = QuestionSubjectTopic(subject: row.subject, topic: row.topic);
    }
    return result;
  }

  Future<List<Question>> getByUuidsInOrder(List<String> uuids) async {
    if (uuids.isEmpty) return const [];
    final byUuid = <String, Question>{};
    for (final chunk in _chunkList(uuids, 800)) {
      final result = await customSelect(
        'SELECT * FROM questions WHERE uuid IN (${List.filled(chunk.length, '?').join(',')})',
        variables: [for (final uuid in chunk) Variable.withString(uuid)],
        readsFrom: {questions},
      ).get();
      for (final row in result) {
        final entry = questions.map(row.data);
        byUuid[entry.uuid] = entry;
      }
    }
    return uuids.map((uuid) => byUuid[uuid]).whereType<Question>().toList();
  }

  Future<List<String>> _randomQuestionUuids({
    required String subject,
    String? topic,
    required int limit,
    required Set<String> attemptedQuestionUuids,
    required bool preferUnseen,
  }) async {
    final whereParts = <String>['subject = ?'];
    final variables = <Variable<Object>>[Variable.withString(subject)];
    if (topic != null) {
      whereParts.add('topic = ?');
      variables.add(Variable.withString(topic));
    }

    if (preferUnseen) {
      final notInClause = _notInClause(attemptedQuestionUuids);
      if (notInClause != null) {
        whereParts.add(notInClause.$1);
        variables.addAll(notInClause.$2);
      }
    } else {
      final inClause = _inClause(attemptedQuestionUuids);
      if (inClause == null) return const [];
      whereParts.add(inClause.$1);
      variables.addAll(inClause.$2);
    }

    variables.add(Variable.withInt(limit));
    final rows = await customSelect(
      'SELECT uuid FROM questions WHERE ${whereParts.join(' AND ')} ORDER BY RANDOM() LIMIT ?',
      variables: variables,
      readsFrom: {questions},
    ).get();
    return rows.map((row) => row.read<String>('uuid')).toList();
  }

  /// Like [_randomQuestionUuids] but across all subjects (no subject/topic filter).
  Future<List<String>> _randomQuestionUuidsMixed({
    required int limit,
    required Set<String> attemptedQuestionUuids,
    required bool preferUnseen,
  }) async {
    final whereParts = <String>['1 = 1'];
    final variables = <Variable<Object>>[];

    if (preferUnseen) {
      final notInClause = _notInClause(attemptedQuestionUuids);
      if (notInClause != null) {
        whereParts.add(notInClause.$1);
        variables.addAll(notInClause.$2);
      }
    } else {
      final inClause = _inClause(attemptedQuestionUuids);
      if (inClause == null) return const [];
      whereParts.add(inClause.$1);
      variables.addAll(inClause.$2);
    }

    variables.add(Variable.withInt(limit));
    final rows = await customSelect(
      'SELECT uuid FROM questions WHERE ${whereParts.join(' AND ')} '
      'ORDER BY RANDOM() LIMIT ?',
      variables: variables,
      readsFrom: {questions},
    ).get();
    return rows.map((row) => row.read<String>('uuid')).toList();
  }

  static (String, List<Variable<Object>>)? _notInClause(Set<String> values) {
    if (values.isEmpty) return null;
    final placeholders = List.filled(values.length, '?').join(',');
    return (
      'uuid NOT IN ($placeholders)',
      values.map((value) => Variable.withString(value) as Variable<Object>).toList(),
    );
  }

  static (String, List<Variable<Object>>)? _inClause(Set<String> values) {
    if (values.isEmpty) return null;
    final placeholders = List.filled(values.length, '?').join(',');
    return (
      'uuid IN ($placeholders)',
      values.map((value) => Variable.withString(value) as Variable<Object>).toList(),
    );
  }

  static List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      final end = (i + chunkSize < list.length) ? i + chunkSize : list.length;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }
}

class SubjectQuestionCount {
  const SubjectQuestionCount({required this.subject, required this.questionCount});

  final String subject;
  final int questionCount;
}

class TopicQuestionCount {
  const TopicQuestionCount({required this.topic, required this.questionCount});

  final String topic;
  final int questionCount;
}

class QuestionSubjectTopic {
  const QuestionSubjectTopic({required this.subject, required this.topic});

  final String subject;
  final String topic;
}

@DriftAccessor(tables: [QuestionTranslations])
class QuestionTranslationsDao extends DatabaseAccessor<UserDatabase>
    with _$QuestionTranslationsDaoMixin {
  QuestionTranslationsDao(super.db);

  Future<QuestionTranslation?> getByQuestionAndLanguage(
    String questionUuid,
    String language,
  ) {
    return (select(questionTranslations)
          ..where(
            (t) =>
                t.questionUuid.equals(questionUuid) &
                t.language.equals(language),
          ))
        .getSingleOrNull();
  }
}

@DriftAccessor(tables: [QuestionTables])
class QuestionTablesDao extends DatabaseAccessor<UserDatabase>
    with _$QuestionTablesDaoMixin {
  QuestionTablesDao(super.db);

  Future<QuestionTable?> getByQuestionUuid(String questionUuid) {
    return (select(questionTables)
          ..where((t) => t.questionUuid.equals(questionUuid)))
        .getSingleOrNull();
  }
}

@DriftAccessor(tables: [TopicTranslations])
class TopicTranslationsDao extends DatabaseAccessor<UserDatabase>
    with _$TopicTranslationsDaoMixin {
  TopicTranslationsDao(super.db);

  Future<TopicTranslation?> getByEnglishName(String englishName) =>
      (select(topicTranslations)
            ..where((t) => t.englishName.equals(englishName)))
          .getSingleOrNull();
}

@DriftAccessor(tables: [Sessions])
class SessionsDao extends DatabaseAccessor<UserDatabase> with _$SessionsDaoMixin {
  SessionsDao(super.db);

  Future<int> insertSession(SessionsCompanion session) =>
      into(sessions).insert(session);

  Future<int> updateSessionStatus(String id, String status) =>
      (update(sessions)..where((t) => t.id.equals(id)))
          .write(SessionsCompanion(status: Value(status)));

  Future<int> updateSessionCompletedAt(String id, DateTime? completedAt) =>
      (update(sessions)..where((t) => t.id.equals(id))).write(
        SessionsCompanion(completedAt: Value(completedAt)),
      );

  Future<int> updateExamRemainingSecs(String id, int? examRemainingSecs) =>
      (update(sessions)..where((t) => t.id.equals(id))).write(
        SessionsCompanion(examRemainingSecs: Value(examRemainingSecs)),
      );

  Future<List<Session>> getAllSessionsOrderedByCreatedAtDesc() =>
      (select(sessions)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Future<Session?> getSessionById(String id) =>
      (select(sessions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Session>> getSessionsBySubject(String subject) =>
      (select(sessions)
            ..where((t) => t.subject.equals(subject))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<List<Session>> getSessionsByMode(String mode) =>
      (select(sessions)
            ..where((t) => t.mode.equals(mode))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<List<Session>> getInProgressSessions() =>
      (select(sessions)
            ..where((t) => t.status.equals('in_progress'))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Whether this PYQ 25-question pack has at least one completed session.
  Future<bool> hasCompletedPyqPack({
    required String subject,
    required int packIndex,
  }) async {
    final topic = 'pyq_25:$packIndex';
    final row = await customSelect(
      "SELECT COUNT(*) AS c FROM sessions "
      "WHERE subject = ? AND topic = ? AND status = 'completed'",
      variables: [
        Variable.withString(subject),
        Variable.withString(topic),
      ],
      readsFrom: {sessions},
    ).getSingle();
    return (row.read<int?>('c') ?? 0) > 0;
  }
}

@DriftAccessor(tables: [SessionQuestions])
class SessionQuestionsDao extends DatabaseAccessor<UserDatabase>
    with _$SessionQuestionsDaoMixin {
  SessionQuestionsDao(super.db);

  Future<void> insertBatch(List<SessionQuestionsCompanion> rows) async {
    if (rows.isEmpty) return;
    await batch((batch) {
      batch.insertAll(sessionQuestions, rows);
    });
  }

  Future<int> insertSessionQuestion(SessionQuestionsCompanion row) =>
      into(sessionQuestions).insert(row);

  Future<int> updateSessionQuestionFields(
    String id, {
    Value<String?> selectedOption = const Value.absent(),
    Value<bool?> isCorrect = const Value.absent(),
    Value<String> status = const Value.absent(),
    Value<int?> timeSpentSecs = const Value.absent(),
    Value<DateTime?> attemptedAt = const Value.absent(),
    Value<String?> confidence = const Value.absent(),
  }) =>
      (update(sessionQuestions)..where((t) => t.id.equals(id))).write(
        SessionQuestionsCompanion(
          selectedOption: selectedOption,
          isCorrect: isCorrect,
          status: status,
          timeSpentSecs: timeSpentSecs,
          attemptedAt: attemptedAt,
          confidence: confidence,
        ),
      );

  Future<int> updateFlagged(String id, bool flagged) =>
      (update(sessionQuestions)..where((t) => t.id.equals(id))).write(
        SessionQuestionsCompanion(flagged: Value(flagged)),
      );

  Future<List<SessionQuestion>> getSessionQuestionsOrdered(String sessionId) =>
      (select(sessionQuestions)
            ..where((t) => t.sessionId.equals(sessionId))
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .get();

  Future<Set<String>> getAllAttemptedQuestionUuids() async {
    final rows = await customSelect(
      'SELECT DISTINCT question_uuid FROM attempts',
      readsFrom: {sessionQuestions},
    ).map((row) => row.read<String>('question_uuid')).get();
    return rows.toSet();
  }

  Future<int> updateAttempt({
    required String id,
    required String selectedOption,
    required bool isCorrect,
    required String status,
    required int? timeSpentSecs,
    required DateTime attemptedAt,
    Value<String?> confidence = const Value.absent(),
  }) {
    return updateSessionQuestionFields(
      id,
      selectedOption: Value(selectedOption),
      isCorrect: Value(isCorrect),
      status: Value(status),
      timeSpentSecs: Value(timeSpentSecs),
      attemptedAt: Value(attemptedAt),
      confidence: confidence,
    );
  }

  /// Scored rows (correct + wrong), used for adaptive confidence rollout.
  Future<int> countScoredAttempts() async {
    final row = await customSelect(
      '''
      SELECT COUNT(*) AS c FROM attempts
      WHERE status IN ('correct', 'wrong')
      ''',
      readsFrom: {sessionQuestions},
    ).getSingle();
    return row.read<int>('c');
  }

  Future<List<ScoredSessionQuestionRow>> getScoredPracticeRows() async {
    return customSelect(
      "SELECT question_uuid, status FROM attempts WHERE status IN ('correct', 'wrong')",
      readsFrom: {sessionQuestions},
    ).map((row) {
      final status = row.read<String>('status');
      return ScoredSessionQuestionRow(
        questionUuid: row.read<String>('question_uuid'),
        isCorrect: status == 'correct',
      );
    }).get();
  }
}

class ScoredSessionQuestionRow {
  const ScoredSessionQuestionRow({
    required this.questionUuid,
    required this.isCorrect,
  });

  final String questionUuid;
  final bool isCorrect;
}

@DriftAccessor(tables: [Bookmarks])
class BookmarksDao extends DatabaseAccessor<UserDatabase> with _$BookmarksDaoMixin {
  BookmarksDao(super.db);

  Future<int> insertBookmark(BookmarksCompanion row) => into(bookmarks).insert(row);

  Future<int> deleteBookmarkByQuestionUuid(String questionUuid) =>
      (delete(bookmarks)..where((t) => t.questionUuid.equals(questionUuid))).go();

  Future<Bookmark?> getBookmarkByQuestionUuid(String questionUuid) =>
      (select(bookmarks)..where((t) => t.questionUuid.equals(questionUuid)))
          .getSingleOrNull();

  Future<bool> isQuestionBookmarked(String questionUuid) async {
    final row = await getBookmarkByQuestionUuid(questionUuid);
    return row != null;
  }

  Future<List<Bookmark>> getAllBookmarksOrderedByCreatedAtDesc() =>
      (select(bookmarks)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Future<List<String>> getRandomBookmarkUuids(int limit) async {
    final rows = await customSelect(
      'SELECT question_uuid FROM bookmarks ORDER BY RANDOM() LIMIT ?',
      variables: [Variable.withInt(limit)],
      readsFrom: {bookmarks},
    ).get();
    return rows.map((row) => row.read<String>('question_uuid')).toList();
  }

  Stream<int> watchBookmarkCount() {
    return customSelect(
      'SELECT COUNT(*) AS c FROM bookmarks',
      readsFrom: {bookmarks},
    ).watchSingle().map((row) => row.read<int>('c'));
  }
}

@DriftAccessor(tables: [RevisionQueue])
class RevisionQueueDao extends DatabaseAccessor<UserDatabase>
    with _$RevisionQueueDaoMixin {
  RevisionQueueDao(super.db);

  Future<void> add({
    required String id,
    required String questionUuid,
    required DateTime dateAddedToQueue,
  }) async {
    final existing = await (select(revisionQueue)
          ..where((t) => t.questionUuid.equals(questionUuid)))
        .getSingleOrNull();
    if (existing == null) {
      await into(revisionQueue).insert(
        RevisionQueueCompanion.insert(
          id: id,
          questionUuid: questionUuid,
          dateAddedToQueue: dateAddedToQueue,
        ),
      );
      return;
    }
    await (update(revisionQueue)..where((t) => t.id.equals(existing.id))).write(
      RevisionQueueCompanion(
        dateAddedToQueue: Value(dateAddedToQueue),
        hasGraduatedFromQueue: const Value(false),
        dateGraduated: const Value(null),
      ),
    );
  }

  Future<void> updateCounts({
    required String questionUuid,
    required bool answeredCorrectly,
  }) async {
    final row = await (select(revisionQueue)
          ..where((t) => t.questionUuid.equals(questionUuid)))
        .getSingleOrNull();
    if (row == null) return;
    final correct = answeredCorrectly
        ? row.numberOfTimesAnsweredCorrectlyInRevision + 1
        : row.numberOfTimesAnsweredCorrectlyInRevision;
    final incorrect = answeredCorrectly
        ? row.numberOfTimesAnsweredIncorrectlyInRevision
        : row.numberOfTimesAnsweredIncorrectlyInRevision + 1;
    await (update(revisionQueue)..where((t) => t.questionUuid.equals(questionUuid))).write(
      RevisionQueueCompanion(
        numberOfTimesAnsweredCorrectlyInRevision: Value(correct),
        numberOfTimesAnsweredIncorrectlyInRevision: Value(incorrect),
      ),
    );
  }

  Future<int> graduate(String questionUuid, DateTime dateGraduated) {
    return (update(revisionQueue)..where((t) => t.questionUuid.equals(questionUuid)))
        .write(
      RevisionQueueCompanion(
        hasGraduatedFromQueue: const Value(true),
        dateGraduated: Value(dateGraduated),
      ),
    );
  }

  Future<RevisionQueueData?> getRevisionQueueItemByQuestionUuid(String questionUuid) =>
      (select(revisionQueue)..where((t) => t.questionUuid.equals(questionUuid)))
          .getSingleOrNull();

  Future<List<RevisionQueueData>> fetchActiveQueue() =>
      (select(revisionQueue)
            ..where((t) => t.hasGraduatedFromQueue.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.dateAddedToQueue)]))
          .get();

  Future<List<String>> fetchActiveQueueRandomized(int limit) async {
    final rows = await customSelect(
      'SELECT question_uuid FROM revision_queue WHERE has_graduated_from_queue = 0 ORDER BY RANDOM() LIMIT ?',
      variables: [Variable.withInt(limit)],
      readsFrom: {revisionQueue},
    ).get();
    return rows.map((row) => row.read<String>('question_uuid')).toList();
  }

  Stream<int> watchActiveQueueCount() {
    return customSelect(
      'SELECT COUNT(*) AS c FROM revision_queue WHERE has_graduated_from_queue = 0',
      readsFrom: {revisionQueue},
    ).watchSingle().map((row) => row.read<int>('c'));
  }

  Future<Map<String, int>> getActiveQueueCountByTopic(String subject) async {
    final rows = await customSelect(
      '''
      SELECT q.topic AS topic, COUNT(*) AS queue_count
      FROM revision_queue rq
      INNER JOIN questions q ON q.uuid = rq.question_uuid
      WHERE rq.has_graduated_from_queue = 0 AND q.subject = ?
      GROUP BY q.topic
      ''',
      variables: [Variable.withString(subject)],
      readsFrom: {revisionQueue, questions},
    ).get();

    return {
      for (final row in rows) row.read<String>('topic'): row.read<int>('queue_count'),
    };
  }

  Future<int> getActiveDistinctTrapTypeCount({
    required String negativeFramingTrapType,
  }) async {
    final row = await customSelect(
      '''
      SELECT COUNT(*) AS trap_count
      FROM (
        SELECT DISTINCT q.trap_type AS trap_key
        FROM revision_queue rq
        INNER JOIN questions q ON q.uuid = rq.question_uuid
        WHERE rq.has_graduated_from_queue = 0 AND q.trap_type IS NOT NULL

        UNION

        SELECT DISTINCT ? AS trap_key
        FROM revision_queue rq
        INNER JOIN questions q ON q.uuid = rq.question_uuid
        WHERE rq.has_graduated_from_queue = 0 AND q.negative_framing = 1
      )
      ''',
      variables: [Variable.withString(negativeFramingTrapType)],
      readsFrom: {revisionQueue, questions},
    ).getSingle();

    return row.read<int>('trap_count');
  }
}

@DriftAccessor(tables: [UserFeatureStats])
class UserFeatureStatsDao extends DatabaseAccessor<UserDatabase>
    with _$UserFeatureStatsDaoMixin {
  UserFeatureStatsDao(super.db);

  Future<void> incrementViews(String featureName, DateTime at) =>
      _bump(featureName, at, views: 1);

  Future<void> incrementStarts(String featureName, DateTime at) =>
      _bump(featureName, at, starts: 1);

  Future<void> incrementCompletions(String featureName, DateTime at) =>
      _bump(featureName, at, completions: 1);

  Future<void> _bump(
    String featureName,
    DateTime at, {
    int views = 0,
    int starts = 0,
    int completions = 0,
  }) async {
    final existing = await (select(userFeatureStats)
          ..where((t) => t.featureName.equals(featureName)))
        .getSingleOrNull();
    if (existing == null) {
      await into(userFeatureStats).insert(
        UserFeatureStatsCompanion.insert(
          featureName: featureName,
          totalViews: Value(views),
          totalStarts: Value(starts),
          totalCompletions: Value(completions),
          lastUsedAt: at,
        ),
      );
      return;
    }
    await (update(userFeatureStats)..where((t) => t.featureName.equals(featureName)))
        .write(
      UserFeatureStatsCompanion(
        totalViews: Value(existing.totalViews + views),
        totalStarts: Value(existing.totalStarts + starts),
        totalCompletions: Value(existing.totalCompletions + completions),
        lastUsedAt: Value(at),
      ),
    );
  }

  Future<List<UserFeatureStat>> fetchAll() =>
      (select(userFeatureStats)..orderBy([(t) => OrderingTerm.asc(t.featureName)]))
          .get();

  Stream<List<UserFeatureStat>> watchAll() =>
      (select(userFeatureStats)..orderBy([(t) => OrderingTerm.asc(t.featureName)]))
          .watch();
}

@DriftAccessor(tables: [UserTrapStats])
class UserTrapStatsDao extends DatabaseAccessor<UserDatabase> with _$UserTrapStatsDaoMixin {
  UserTrapStatsDao(super.db);

  Future<void> recordFailure({
    required String trapType,
    required DateTime at,
  }) async {
    final existing = await (select(userTrapStats)
          ..where((t) => t.trapType.equals(trapType)))
        .getSingleOrNull();
    if (existing == null) {
      await into(userTrapStats).insert(
        UserTrapStatsCompanion.insert(
          trapType: trapType,
          totalFailures: const Value(1),
          lastFailedAt: at,
        ),
      );
      return;
    }
    await (update(userTrapStats)..where((t) => t.trapType.equals(trapType))).write(
      UserTrapStatsCompanion(
        totalFailures: Value(existing.totalFailures + 1),
        lastFailedAt: Value(at),
      ),
    );
  }
}

@DriftAccessor(tables: [UserTopicStats])
class UserTopicStatsDao extends DatabaseAccessor<UserDatabase>
    with _$UserTopicStatsDaoMixin {
  UserTopicStatsDao(super.db);

  Future<void> upsertAfterSessionCompletion({
    required String subject,
    required String topic,
    required int attemptedToAdd,
    required int correctToAdd,
    required int wrongToAdd,
    required int timeSpentSecsSum,
    required DateTime attemptedAt,
  }) async {
    final existing = await (select(userTopicStats)
          ..where((t) => t.subject.equals(subject) & t.topic.equals(topic)))
        .getSingleOrNull();
    if (existing == null) {
      final accuracy =
          attemptedToAdd == 0 ? 0.0 : (correctToAdd / attemptedToAdd) * 100;
      await into(userTopicStats).insert(
        UserTopicStatsCompanion.insert(
          subject: subject,
          topic: topic,
          totalAttempted: Value(attemptedToAdd),
          totalCorrect: Value(correctToAdd),
          wrongAttempts: Value(wrongToAdd),
          totalTimeSpentSecs: Value(timeSpentSecsSum),
          accuracyPercentage: Value(accuracy),
          lastAttemptedAt: attemptedAt,
        ),
      );
      return;
    }
    final newAttempted = existing.totalAttempted + attemptedToAdd;
    final newCorrect = existing.totalCorrect + correctToAdd;
    final newWrong = existing.wrongAttempts + wrongToAdd;
    final newTime = existing.totalTimeSpentSecs + timeSpentSecsSum;
    final newAccuracy = newAttempted == 0 ? 0.0 : (newCorrect / newAttempted) * 100;
    await (update(userTopicStats)..where((t) => t.id.equals(existing.id))).write(
      UserTopicStatsCompanion(
        totalAttempted: Value(newAttempted),
        totalCorrect: Value(newCorrect),
        wrongAttempts: Value(newWrong),
        totalTimeSpentSecs: Value(newTime),
        accuracyPercentage: Value(newAccuracy),
        lastAttemptedAt: Value(attemptedAt),
      ),
    );
  }

  Future<List<UserTopicStat>> fetchBySubject(String subject) =>
      (select(userTopicStats)
            ..where((t) => t.subject.equals(subject))
            ..orderBy([(t) => OrderingTerm.asc(t.topic)]))
          .get();

  Future<List<UserTopicStat>> fetchAll() =>
      (select(userTopicStats)..orderBy([(t) => OrderingTerm.asc(t.subject)])).get();

  /// Keys `subject||topic` where the learner is under ~55% after enough attempts.
  Future<Set<String>> weakTopicKeysAmong(
    List<({String subject, String topic})> pairs,
  ) async {
    final seen = <String>{};
    final out = <String>{};
    for (final p in pairs) {
      final key = '${p.subject}||${p.topic}';
      if (seen.contains(key)) continue;
      seen.add(key);
      final row = await (select(userTopicStats)
            ..where((t) => t.subject.equals(p.subject) & t.topic.equals(p.topic)))
          .getSingleOrNull();
      if (row != null &&
          row.totalAttempted >= 5 &&
          row.accuracyPercentage < 55.0) {
        out.add(key);
      }
    }
    return out;
  }
}

@DriftDatabase(
  tables: [
    Questions,
    QuestionTranslations,
    QuestionTables,
    TopicTranslations,
    Sessions,
    SessionQuestions,
    Bookmarks,
    RevisionQueue,
    UserTopicStats,
    UserFeatureStats,
    UserTrapStats,
  ],
  daos: [
    QuestionsDao,
    QuestionTranslationsDao,
    QuestionTablesDao,
    TopicTranslationsDao,
    SessionsDao,
    SessionQuestionsDao,
    BookmarksDao,
    RevisionQueueDao,
    UserTopicStatsDao,
    UserFeatureStatsDao,
    UserTrapStatsDao,
  ],
)
class UserDatabase extends _$UserDatabase {
  UserDatabase([QueryExecutor? executor]) : super(executor ?? _openUnifiedDb());

  @override
  int get schemaVersion => 5;

  /// True when [column] already exists on [table] (handles prebuilt DBs whose
  /// `user_version` lags behind the actual schema).
  Future<bool> _sqliteColumnExists(String table, String column) async {
    final row = await customSelect(
      "SELECT COUNT(*) AS c FROM pragma_table_info('$table') "
      "WHERE name = '$column'",
      readsFrom: {
        questions,
        sessions,
        sessionQuestions,
        userTopicStats,
      },
    ).getSingle();
    return (row.read<int?>('c') ?? 0) > 0;
  }

  Future<bool> _sqliteTableExists(String name) async {
    final row = await customSelect(
      "SELECT COUNT(*) AS c FROM sqlite_master "
      "WHERE type = 'table' AND name = '$name'",
      readsFrom: {
        questions,
        sessions,
        sessionQuestions,
        userTopicStats,
      },
    ).getSingle();
    return (row.read<int?>('c') ?? 0) > 0;
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          // Performance index for subject-scoped queries.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_questions_subject '
            'ON questions(subject)',
          );
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            if (!await _sqliteColumnExists('sessions', 'analytics_feature_key')) {
              await m.addColumn(sessions, sessions.analyticsFeatureKey);
            }
            if (!await _sqliteColumnExists('user_topic_stats', 'wrong_attempts')) {
              await m.addColumn(userTopicStats, userTopicStats.wrongAttempts);
            }
            if (!await _sqliteColumnExists(
              'user_topic_stats',
              'total_time_spent_secs',
            )) {
              await m.addColumn(
                userTopicStats,
                userTopicStats.totalTimeSpentSecs,
              );
            }
            if (!await _sqliteTableExists('user_feature_stats')) {
              await m.createTable(userFeatureStats);
            }
            if (!await _sqliteTableExists('user_trap_stats')) {
              await m.createTable(userTrapStats);
            }
            await customStatement(
              'UPDATE user_topic_stats SET wrong_attempts = '
              'CASE WHEN total_attempted - total_correct > 0 '
              'THEN total_attempted - total_correct ELSE 0 END',
            );
          }
          if (from < 3) {
            // Add subject index for existing installations.
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_questions_subject '
              'ON questions(subject)',
            );
          }
          if (from < 4) {
            if (!await _sqliteColumnExists('attempts', 'confidence')) {
              await m.addColumn(sessionQuestions, sessionQuestions.confidence);
            }
          }
          if (from < 5) {
            if (!await _sqliteColumnExists('questions', 'paper_order')) {
              await m.addColumn(questions, questions.paperOrder);
            }
          }
        },
      );
}

LazyDatabase _openUnifiedDb() => user_db_connection.openUserDb();
