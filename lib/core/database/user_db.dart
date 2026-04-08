import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'user_db.g.dart';

class Sessions extends Table {
  TextColumn get id => text()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  TextColumn get subjectSlug => text()();
  TextColumn get topicSlug => text().nullable()();
  TextColumn get subTopicSlug => text().nullable()();

  TextColumn get mode => text()();
  TextColumn get status => text()();

  IntColumn get questionCount => integer()();
  BoolColumn get isTimed => boolean()();

  IntColumn get timeLimitSecs => integer().nullable()();

  /// Last saved remaining seconds for timed exam (approximate resume).
  IntColumn get examRemainingSecs => integer().nullable()();

  TextColumn get language => text().withDefault(const Constant('en'))();

  @override
  Set<Column> get primaryKey => {id};
}

class SessionQuestions extends Table {
  TextColumn get id => text()();

  TextColumn get sessionId => text().references(Sessions, #id)();
  TextColumn get questionUuid => text()();

  IntColumn get position => integer()();

  TextColumn get selectedOption => text().nullable()();

  BoolColumn get isCorrect => boolean().nullable()();

  TextColumn get status => text().withDefault(const Constant('unattempted'))();

  IntColumn get timeSpentSecs => integer().nullable()();
  BoolColumn get flagged => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Bookmarks extends Table {
  TextColumn get id => text()();

  TextColumn get questionUuid => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class RevisionQueue extends Table {
  TextColumn get id => text()();

  TextColumn get questionUuid => text().unique()();

  DateTimeColumn get addedAt => dateTime()();

  TextColumn get reason => text()();

  IntColumn get correctStreak => integer().withDefault(const Constant(0))();

  DateTimeColumn get lastCorrectAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
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

  Future<List<Session>> getSessionsBySubjectSlug(String subjectSlug) =>
      (select(sessions)
            ..where((t) => t.subjectSlug.equals(subjectSlug))
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
}

@DriftAccessor(tables: [SessionQuestions])
class SessionQuestionsDao extends DatabaseAccessor<UserDatabase>
    with _$SessionQuestionsDaoMixin {
  SessionQuestionsDao(super.db);

  Future<int> insertSessionQuestion(SessionQuestionsCompanion row) =>
      into(sessionQuestions).insert(row);

  Future<int> updateSessionQuestionFields(
    String id, {
    Value<String?> selectedOption = const Value.absent(),
    Value<bool?> isCorrect = const Value.absent(),
    Value<String> status = const Value.absent(),
    Value<int?> timeSpentSecs = const Value.absent(),
  }) =>
      (update(sessionQuestions)..where((t) => t.id.equals(id))).write(
        SessionQuestionsCompanion(
          selectedOption: selectedOption,
          isCorrect: isCorrect,
          status: status,
          timeSpentSecs: timeSpentSecs,
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
      'SELECT DISTINCT question_uuid FROM session_questions',
      readsFrom: {sessionQuestions},
    ).map((row) => row.read<String>('question_uuid')).get();
    return rows.toSet();
  }

  /// Rows that count toward accuracy (correct / wrong only).
  Future<List<ScoredSessionQuestionRow>> getScoredPracticeRows() async {
    return customSelect(
      "SELECT question_uuid, status, is_correct FROM session_questions "
      "WHERE status IN ('correct', 'wrong')",
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

/// One scored attempt row for catalog statistics.
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
}

@DriftAccessor(tables: [RevisionQueue])
class RevisionQueueDao extends DatabaseAccessor<UserDatabase>
    with _$RevisionQueueDaoMixin {
  RevisionQueueDao(super.db);

  /// Inserts or updates existing row: refreshes [addedAt], resets streak and [lastCorrectAt].
  Future<void> insertOrUpdateRevisionItem({
    required String id,
    required String questionUuid,
    required DateTime addedAt,
    required String reason,
  }) async {
    final existing = await (select(revisionQueue)
          ..where((t) => t.questionUuid.equals(questionUuid)))
        .getSingleOrNull();
    if (existing != null) {
      await (update(revisionQueue)..where((t) => t.id.equals(existing.id))).write(
        RevisionQueueCompanion(
          addedAt: Value(addedAt),
          correctStreak: const Value(0),
          lastCorrectAt: const Value.absent(),
        ),
      );
    } else {
      await into(revisionQueue).insert(
        RevisionQueueCompanion.insert(
          id: id,
          questionUuid: questionUuid,
          addedAt: addedAt,
          reason: reason,
        ),
      );
    }
  }

  Future<void> incrementCorrectStreakForQuestion(String questionUuid) async {
    final row = await (select(revisionQueue)
          ..where((t) => t.questionUuid.equals(questionUuid)))
        .getSingleOrNull();
    if (row == null) return;
    await (update(revisionQueue)..where((t) => t.id.equals(row.id))).write(
      RevisionQueueCompanion(
        correctStreak: Value(row.correctStreak + 1),
        lastCorrectAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<RevisionQueueData>> getActiveRevisionItems() =>
      (select(revisionQueue)..where((t) => t.correctStreak.isSmallerThanValue(2)))
          .get();

  Future<RevisionQueueData?> getRevisionQueueItemByQuestionUuid(String questionUuid) =>
      (select(revisionQueue)..where((t) => t.questionUuid.equals(questionUuid)))
          .getSingleOrNull();

  Future<void> updateRevisionQueueProgress({
    required String questionUuid,
    required int correctStreak,
    required DateTime? lastCorrectAt,
  }) async {
    await (update(revisionQueue)..where((t) => t.questionUuid.equals(questionUuid))).write(
      RevisionQueueCompanion(
        correctStreak: Value(correctStreak),
        lastCorrectAt: Value(lastCorrectAt),
      ),
    );
  }

  Future<List<RevisionQueueData>> getActiveRevisionItemsOrdered() =>
      (select(revisionQueue)
            ..where((t) => t.correctStreak.isSmallerThanValue(2))
            ..orderBy([
              (t) => OrderingTerm.asc(t.addedAt),
              (t) => OrderingTerm.asc(t.correctStreak),
            ]))
          .get();


  Future<int> getActiveRevisionItemCount() async {
    final rows = await customSelect(
      'SELECT COUNT(*) AS c FROM revision_queue WHERE correct_streak < 2',
      readsFrom: {revisionQueue},
    ).get();
    return rows.first.read<int>('c');
  }

  Future<List<String>> getActiveRevisionQuestionUuids() async {
    final rows = await customSelect(
      'SELECT question_uuid FROM revision_queue WHERE correct_streak < 2',
      readsFrom: {revisionQueue},
    ).map((row) => row.read<String>('question_uuid')).get();
    return rows;
  }
}

@DriftDatabase(
  tables: [Sessions, SessionQuestions, Bookmarks, RevisionQueue],
  daos: [SessionsDao, SessionQuestionsDao, BookmarksDao, RevisionQueueDao],
)
class UserDatabase extends _$UserDatabase {
  UserDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'upsc_user_data'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(sessions, sessions.examRemainingSecs);
          }
        },
      );
}
