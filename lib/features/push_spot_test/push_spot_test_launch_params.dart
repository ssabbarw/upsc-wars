import '../../../core/deep_link/share_link_parser.dart';

/// Inputs for starting a push spot test (notification, deep link, or debug UI).
class PushSpotTestLaunchParams {
  const PushSpotTestLaunchParams({
    this.subject = '',
    this.topic = '',
    this.subTopic,
    this.questionUuid,
  });

  final String subject;
  final String topic;
  final String? subTopic;
  final String? questionUuid;

  String? get trimmedQuestionUuid {
    final s = questionUuid?.trim();
    if (s == null || s.isEmpty) return null;
    return s;
  }

  /// True when enough data exists to attempt a launch.
  bool get isValid {
    final uuid = trimmedQuestionUuid;
    if (uuid != null) return isUuid(uuid);
    return subject.trim().isNotEmpty && topic.trim().isNotEmpty;
  }

  String? get validationError {
    final uuid = trimmedQuestionUuid;
    if (uuid != null) {
      if (!isUuid(uuid)) return 'Invalid question UUID.';
      return null;
    }
    if (subject.trim().isEmpty || topic.trim().isEmpty) {
      return 'Provide question_uuid or both subject and topic.';
    }
    return null;
  }

  Map<String, String> toQueryParameters() {
    final uuid = trimmedQuestionUuid;
    return {
      if (subject.trim().isNotEmpty) 'subject': subject.trim(),
      if (topic.trim().isNotEmpty) 'topic': topic.trim(),
      if (subTopic != null && subTopic!.trim().isNotEmpty)
        'subtopic': subTopic!.trim(),
      if (uuid != null) 'question_uuid': uuid,
    };
  }

  static PushSpotTestLaunchParams fromQuery(Map<String, String> q) {
    final subRaw = q['subtopic'] ?? q['sub_topic'];
    final sub = subRaw?.trim();
    return PushSpotTestLaunchParams(
      subject: q['subject']?.trim() ?? '',
      topic: q['topic']?.trim() ?? '',
      subTopic: sub != null && sub.isNotEmpty ? sub : null,
      questionUuid: q['question_uuid'] ?? q['questionUuid'],
    );
  }
}
