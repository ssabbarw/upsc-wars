import 'package:upsc_wars/core/database/user_db.dart';
import 'package:upsc_wars/core/domain/entities/revision_queue_item.dart';
import 'package:upsc_wars/core/domain/entities/weak_concept_group.dart';
import 'package:upsc_wars/core/domain/entities/trap_pattern_group.dart';
import 'package:upsc_wars/core/parsers/question_display_text_parser.dart';
import 'package:upsc_wars/features/revision_queue/domain/repositories/revision_repository.dart';

const _negativeFramingTrapType = 'negative-framing';

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
        conceptAnchor: q.conceptAnchor,
        subTopic: q.subTopic,
        trapType: q.trapType,
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
        updated.numberOfTimesAnsweredCorrectlyInRevision >= 1) {
      await _userDb.revisionQueueDao.graduate(questionUuid, DateTime.now());
    }
  }

  @override
  Future<List<WeakSubTopicGroup>> getWeakSubTopicGroups() async {
    final rows = await _userDb.revisionQueueDao.fetchActiveQueue();
    // subject|subTopic -> (subject, subTopic, failureCount, uuids)
    final map = <String, ({String subject, String subTopic, int failures, List<String> uuids})>{};
    for (final r in rows) {
      final q = await _userDb.questionsDao.getByUuid(r.questionUuid);
      if (q == null) continue;
      final sub = q.subTopic;
      final key = '${q.subject}|$sub';
      final existing = map[key];
      if (existing == null) {
        map[key] = (
          subject: q.subject,
          subTopic: sub,
          failures: r.numberOfTimesAnsweredIncorrectlyInRevision + 1,
          uuids: [r.questionUuid],
        );
      } else {
        map[key] = (
          subject: existing.subject,
          subTopic: existing.subTopic,
          failures: existing.failures + r.numberOfTimesAnsweredIncorrectlyInRevision + 1,
          uuids: [...existing.uuids, r.questionUuid],
        );
      }
    }
    final groups = map.entries
        .map((e) => WeakSubTopicGroup(
              subject: e.value.subject,
              subTopic: e.value.subTopic,
              failureCount: e.value.failures,
              questionUuids: e.value.uuids,
            ))
        .toList()
      ..sort((a, b) {
        final bySubject = a.subject.toLowerCase().compareTo(b.subject.toLowerCase());
        if (bySubject != 0) return bySubject;
        return b.failureCount.compareTo(a.failureCount);
      });
    return groups;
  }

  @override
  Future<List<TrapPatternGroup>> getWeakTrapGroups() async {
    final rows = await _userDb.revisionQueueDao.fetchActiveQueue();
    final map = <String, List<String>>{};
    for (final r in rows) {
      final q = await _userDb.questionsDao.getByUuid(r.questionUuid);
      if (q == null) continue;
      final trap = q.trapType;
      if (trap != null) {
        map.putIfAbsent(trap, () => []).add(r.questionUuid);
      }
      if (q.negativeFraming) {
        map.putIfAbsent(_negativeFramingTrapType, () => []).add(r.questionUuid);
      }
    }
    return map.entries
        .map((e) => TrapPatternGroup(
              trapType: e.key,
              questionCount: e.value.length,
              questionUuids: e.value,
            ))
        .toList()
      ..sort((a, b) => b.questionCount.compareTo(a.questionCount));
  }

  @override
  Future<int> getUniqueSubTopicCount() async =>
      (await getWeakSubTopicGroups()).length;

  @override
  Future<int> getUniqueTrapTypeCount() async =>
      _userDb.revisionQueueDao.getActiveDistinctTrapTypeCount(
        negativeFramingTrapType: _negativeFramingTrapType,
      );
}
