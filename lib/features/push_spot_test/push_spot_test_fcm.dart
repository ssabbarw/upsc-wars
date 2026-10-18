/// Send from Firebase Console (or server) with **custom data**:
///
/// * `kind` = [PushSpotTestFcm.kind] (`push_spot_test`)
/// * `subject` — catalog subject (e.g. `Economy`; `economy` also resolves)
/// * `topic` — catalog topic name (e.g. `Agriculture`)
/// * `subtopic` or `sub_topic` — optional subtopic slug
/// * `question_uuid` or `questionUuid` — optional exact MCQ to serve (when set,
///   subject/topic are optional and taken from the question row if omitted)
///
/// Tapping opens a 1-question learning test, then [PushSpotResultsScreen].
abstract final class PushSpotTestFcm {
  static const kind = 'push_spot_test';

  static const dataKeyKind = 'kind';
  static const dataKeySubject = 'subject';
  static const dataKeyTopic = 'topic';
  static const dataKeySubtopic = 'subtopic';
  static const dataKeySubTopicAlt = 'sub_topic';
  static const dataKeyQuestionUuid = 'question_uuid';
  static const dataKeyQuestionUuidAlt = 'questionUuid';

  /// Reads an exact question id from FCM custom data, if present.
  static String? questionUuidFromData(Map<String, dynamic> data) {
    final raw = data[dataKeyQuestionUuid] ?? data[dataKeyQuestionUuidAlt];
    final s = raw?.toString().trim();
    if (s == null || s.isEmpty) return null;
    return s;
  }
}
