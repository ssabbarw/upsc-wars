import 'package:upsc_wars/core/database/user_db.dart';
import 'package:upsc_wars/core/domain/entities/revision_queue_item.dart';
import 'package:upsc_wars/core/parsers/question_display_text_parser.dart';
import 'package:upsc_wars/features/revision_queue/domain/repositories/revision_repository.dart';

class RevisionRepositoryImpl implements RevisionRepository {
  const RevisionRepositoryImpl({required UserDatabase userDb}) : _userDb = userDb;
  final UserDatabase _userDb;

  @override
  Future<List<RevisionQueueItem>> getActiveRevisionQueueItems() async {
    final rows = await _userDb.revisionQueueDao.fetchActiveQueue();
    final items = <RevisionQueueItem>[];
    for (final r in rows) {
      final q = await _userDb.questionsDao.getByUuid(r.questionUuid);
      if (q == null) continue;
      final parsed = QuestionDisplayTextParser.parse(q.enDisplayText ?? '');
      items.add(RevisionQueueItem(
        id: r.id,
        questionUuid: r.questionUuid,
        dateAddedToQueue: r.dateAddedToQueue,
        numberOfTimesAnsweredCorrectlyInRevision:
            r.numberOfTimesAnsweredCorrectlyInRevision,
        numberOfTimesAnsweredIncorrectlyInRevision:
            r.numberOfTimesAnsweredIncorrectlyInRevision,
        hasGraduatedFromQueue: r.hasGraduatedFromQueue,
        dateGraduated: r.dateGraduated,
        subject: q.subject,
        topic: q.topic,
        questionStem: parsed.stem,
      ));
    }
    return items;
  }

  @override
  Future<int> getActiveRevisionQueueCount() async =>
      (await _userDb.revisionQueueDao.fetchActiveQueue()).length;

  @override
  Future<List<String>> getActiveRevisionSubjectSlugs({int limit = 3}) async {
    final uuids =
        (await _userDb.revisionQueueDao.fetchActiveQueue()).map((e) => e.questionUuid).toList();
    if (uuids.isEmpty) return const [];
    final map = <String, String>{};
    for (final uuid in uuids) {
      final q = await _userDb.questionsDao.getByUuid(uuid);
      if (q != null) {
        map[uuid] = q.subject;
      }
    }
    final seen = <String>[];
    for (final uuid in uuids) {
      final subject = map[uuid];
      if (subject == null) continue;
      if (!seen.contains(subject)) seen.add(subject);
      if (seen.length >= limit) break;
    }
    return seen;
  }

  @override
  Future<void> updateRevisionQueueProgress(String questionUuid) async {
    final row = (await _userDb.revisionQueueDao.fetchActiveQueue())
        .where((e) => e.questionUuid == questionUuid)
        .firstOrNull;
    if (row == null) return;
    await _userDb.revisionQueueDao.updateCounts(
      questionUuid: questionUuid,
      answeredCorrectly: true,
    );
    final updated = (await _userDb.revisionQueueDao.fetchActiveQueue())
        .where((e) => e.questionUuid == questionUuid)
        .firstOrNull;
    if (updated != null &&
        updated.numberOfTimesAnsweredCorrectlyInRevision >= 2) {
      await _userDb.revisionQueueDao.graduate(questionUuid, DateTime.now());
    }
  }
}
