import 'package:drift/drift.dart';

import '../../../core/constants/daily_drill_constants.dart';
import '../../../core/database/user_db.dart';
import '../../../l10n/l10n.dart';

/// Afternoon drill pool: incorrect MCQs, or bookmarked MCQs.
enum DailyRevisionPool { missed, saved }

/// 12 PM–6 PM daily drill: a short set from the revision queue.
abstract final class DailyRevision {
  DailyRevision._();

  static const sessionSubject = 'daily_revision';
  static const questionCount = DailyDrillConstants.questionCount;

  static String get incorrectLabel => appL10n.revisionIncorrectMcqs;
  static String get bookmarkedLabel => appL10n.revisionBookmarkedMcqs;
  static String get emptyQueueLine => appL10n.revisionQueueEmptyLine;

  static String _incorrectBit(int n) => appL10n.revisionCountIncorrect(n);

  static String _bookmarkBit(int n) => appL10n.revisionCountBookmark(n);

  static String countsLine({required int missed, required int saved}) {
    if (missed <= 0 && saved <= 0) return emptyQueueLine;
    if (missed <= 0) return _bookmarkBit(saved);
    if (saved <= 0) return _incorrectBit(missed);
    return '${_incorrectBit(missed)} · ${_bookmarkBit(saved)}';
  }

  /// Two lines for the narrow home tile so "bookmarks" never orphans.
  static String countsStacked({required int missed, required int saved}) {
    if (missed <= 0 && saved <= 0) return emptyQueueLine;
    if (missed <= 0) return _bookmarkBit(saved);
    if (saved <= 0) return _incorrectBit(missed);
    return '${_incorrectBit(missed)}\n${_bookmarkBit(saved)}';
  }

  static String poolCountLabel(int available) =>
      available <= 0 ? appL10n.commonNone : '$available';

  static String analyticsSubject(DailyRevisionPool pool) => switch (pool) {
    DailyRevisionPool.missed => 'revision_missed',
    DailyRevisionPool.saved => 'revision_saved',
  };

  /// Distinct wrong questions, newest first, capped at [limit].
  static Future<List<String>> queryWrongUuids(
    UserDatabase db, {
    int limit = questionCount,
  }) async {
    final rows = await db
        .customSelect(
          '''
          SELECT a.question_uuid AS quid
          FROM attempts a
          WHERE a.is_correct = 0
            AND a.status = 'wrong'
            AND a.attempted_at IS NOT NULL
          GROUP BY a.question_uuid
          ORDER BY MAX(a.attempted_at) DESC
          LIMIT ?
          ''',
          variables: [Variable.withInt(limit)],
          readsFrom: {db.sessionQuestions},
        )
        .get();
    return [for (final r in rows) r.read<String>('quid')];
  }

  static Future<int> countWrongUuids(UserDatabase db) async {
    final row = await db
        .customSelect(
          '''
          SELECT COUNT(*) AS c FROM (
            SELECT a.question_uuid
            FROM attempts a
            WHERE a.is_correct = 0
              AND a.status = 'wrong'
            GROUP BY a.question_uuid
          ) AS wrongs
          ''',
          readsFrom: {db.sessionQuestions},
        )
        .getSingle();
    return row.read<int>('c');
  }

  static Future<List<String>> queryBookmarkUuids(
    UserDatabase db, {
    int limit = questionCount,
  }) async {
    final rows = await db
        .customSelect(
          '''
          SELECT question_uuid AS quid
          FROM bookmarks
          ORDER BY created_at DESC
          LIMIT ?
          ''',
          variables: [Variable.withInt(limit)],
          readsFrom: {db.bookmarks},
        )
        .get();
    return [for (final r in rows) r.read<String>('quid')];
  }

  static Future<int> countBookmarks(UserDatabase db) async {
    final row = await db
        .customSelect(
          'SELECT COUNT(*) AS c FROM bookmarks',
          readsFrom: {db.bookmarks},
        )
        .getSingle();
    return row.read<int>('c');
  }
}
