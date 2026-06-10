import '../../../core/database/user_db.dart';

/// Picks one random MCQ for the spot-test composer (shuffle preview).
Future<Question?> pickSpotComposerQuestion(
  UserDatabase db, {
  required String subject,
  required String topic,
  String? subTopic,
  Set<String> excludeUuids = const {},
}) async {
  final list = subTopic != null && subTopic.isNotEmpty
      ? await db.questionsDao.getUnseenFirstByTopicSubTopic(
          subject: subject,
          topic: topic,
          subTopic: subTopic,
          limit: 1,
          attemptedQuestionUuids: excludeUuids,
        )
      : await db.questionsDao.getUnseenFirstByTopic(
          subject: subject,
          topic: topic,
          limit: 1,
          attemptedQuestionUuids: excludeUuids,
        );
  return list.isEmpty ? null : list.first;
}
