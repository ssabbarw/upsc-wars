import 'package:intl/intl.dart';
import 'package:upsc_wars/core/database/question_db.dart';
import 'package:upsc_wars/core/database/user_db.dart';
import 'package:upsc_wars/core/domain/entities/revision_queue_item.dart';
import 'package:upsc_wars/core/parsers/question_display_text_parser.dart';
import 'package:upsc_wars/features/revision_queue/domain/repositories/revision_repository.dart';

class RevisionRepositoryImpl implements RevisionRepository {
  const RevisionRepositoryImpl({required UserDatabase userDb, required QuestionDb questionDb})
      : _userDb = userDb,
        _questionDb = questionDb;
  final UserDatabase _userDb;
  final QuestionDb _questionDb;

  @override
  Future<List<RevisionQueueItem>> getActiveRevisionQueueItems() async {
    final rows = await _userDb.revisionQueueDao.getActiveRevisionItemsOrdered();
    final items = <RevisionQueueItem>[];
    for (final r in rows) {
      final q = (await _questionDb.getQuestionsByUuids([r.questionUuid])).firstOrNull;
      final tr = await _questionDb.getQuestionTranslation(r.questionUuid, 'en');
      if (q == null || tr == null) continue;
      final parsed = QuestionDisplayTextParser.parse(tr.displayText);
      items.add(RevisionQueueItem(
        id: r.id,
        questionUuid: r.questionUuid,
        addedAt: r.addedAt,
        reason: r.reason,
        correctStreak: r.correctStreak,
        lastCorrectAt: r.lastCorrectAt,
        subjectSlug: q.subjectSlug,
        topicSlug: q.topicSlug,
        questionStem: parsed.stem,
      ));
    }
    return items;
  }

  @override
  Future<int> getActiveRevisionQueueCount() => _userDb.revisionQueueDao.getActiveRevisionItemCount();

  @override
  Future<List<String>> getActiveRevisionSubjectSlugs({int limit = 3}) async {
    final uuids = await _userDb.revisionQueueDao.getActiveRevisionQuestionUuids();
    if (uuids.isEmpty) return const [];
    final map = await _questionDb.getSubjectTopicForUuids(uuids);
    final seen = <String>[];
    for (final uuid in uuids) {
      final slug = map[uuid]?.subjectSlug;
      if (slug == null) continue;
      if (!seen.contains(slug)) seen.add(slug);
      if (seen.length >= limit) break;
    }
    return seen;
  }

  @override
  Future<void> updateRevisionQueueProgress(String questionUuid) async {
    final row = await _userDb.revisionQueueDao.getRevisionQueueItemByQuestionUuid(questionUuid);
    if (row == null || row.correctStreak >= 2) return;
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final last = row.lastCorrectAt == null ? null : DateFormat('yyyy-MM-dd').format(row.lastCorrectAt!);

    if (row.correctStreak == 0) {
      await _userDb.revisionQueueDao.updateRevisionQueueProgress(questionUuid: questionUuid, correctStreak: 1, lastCorrectAt: now);
      return;
    }
    if (row.correctStreak == 1 && last != today) {
      await _userDb.revisionQueueDao.updateRevisionQueueProgress(questionUuid: questionUuid, correctStreak: 2, lastCorrectAt: now);
    }
  }
}
