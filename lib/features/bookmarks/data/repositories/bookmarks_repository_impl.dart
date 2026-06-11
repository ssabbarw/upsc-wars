import 'dart:async';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:upsc_wars/core/analytics/activation_milestones.dart';
import 'package:upsc_wars/core/analytics/analytics_service.dart';
import 'package:upsc_wars/core/database/user_db.dart';
import 'package:upsc_wars/core/domain/entities/bookmark_item.dart';
import 'package:upsc_wars/core/parsers/question_display_text_parser.dart';
import 'package:upsc_wars/core/providers/prefs_provider.dart';
import 'package:upsc_wars/core/services/question_stats_sync_service.dart';
import 'package:upsc_wars/features/bookmarks/domain/repositories/bookmarks_repository.dart';

class BookmarksRepositoryImpl implements BookmarksRepository {
  const BookmarksRepositoryImpl({
    required UserDatabase userDb,
    required PrefsService prefs,
    required AnalyticsService analytics,
  })  : _userDb = userDb,
        _prefs = prefs,
        _analytics = analytics;
  final UserDatabase _userDb;
  final PrefsService _prefs;
  final AnalyticsService _analytics;
  static const _uuid = Uuid();

  @override
  Future<List<BookmarkItem>> getBookmarks() async {
    final rows = await _userDb.bookmarksDao.getAllBookmarksOrderedByCreatedAtDesc();
    final out = <BookmarkItem>[];
    for (final b in rows) {
      final q = await _userDb.questionsDao.getByUuid(b.questionUuid);
      if (q == null) continue;
      out.add(BookmarkItem(
        id: b.id,
        questionUuid: b.questionUuid,
        createdAt: b.createdAt,
        userNote: b.userNote,
        subject: q.subject,
        topic: q.topic,
        questionStem:
            QuestionDisplayTextParser.parse(q.enDisplayText ?? '').stem,
      ));
    }
    return out;
  }

  @override
  Future<void> addBookmark(String questionUuid, {String? note}) async {
    final existing = await _userDb.bookmarksDao.getBookmarkByQuestionUuid(questionUuid);
    if (existing == null) {
      await _userDb.bookmarksDao.insertBookmark(
        BookmarksCompanion.insert(
          id: _uuid.v4(),
          questionUuid: questionUuid,
          createdAt: DateTime.now(),
          userNote: Value(note),
        ),
      );
      unawaited(
        logActivationMilestoneForServices(
          _analytics,
          _prefs,
          id: ActivationMilestones.firstBookmark,
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
  Future<void> removeBookmark(String questionUuid) => _userDb.bookmarksDao.deleteBookmarkByQuestionUuid(questionUuid);

  @override
  Future<bool> isBookmarked(String questionUuid) => _userDb.bookmarksDao.isQuestionBookmarked(questionUuid);

  @override
  Future<int> count() async => (await _userDb.bookmarksDao.getAllBookmarksOrderedByCreatedAtDesc()).length;
}
