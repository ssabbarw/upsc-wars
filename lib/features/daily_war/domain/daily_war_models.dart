/// One topic slot inside a Daily War paper (usually two per night).
class DailyWarTopicRef {
  const DailyWarTopicRef({
    required this.subjectSlug,
    required this.topic,
  });

  final String subjectSlug;
  final String topic;

  factory DailyWarTopicRef.fromMap(Map<String, dynamic> map) {
    return DailyWarTopicRef(
      subjectSlug: (map['subject'] as String? ?? '').trim(),
      topic: (map['topic'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toMap() => {
        'subject': subjectSlug,
        'topic': topic,
      };

  @override
  String toString() => '$subjectSlug::$topic';
}

/// Public Firestore document for `daily_wars/{dateId}`.
class DailyWarDoc {
  const DailyWarDoc({
    required this.dateId,
    required this.kind,
    required this.topics,
    required this.questionCount,
    required this.status,
    this.questionUuids = const [],
    this.participantCount,
    this.lobbyCount,
    this.nextTopics = const [],
    this.rankedAtMs,
  });

  /// `YYYY-MM-DD` IST.
  final String dateId;

  /// `daily` or `grand`.
  final String kind;

  final List<DailyWarTopicRef> topics;
  final int questionCount;

  /// `announced` | `questions_published` | `closed` | `ranked`
  final String status;

  /// Empty until questions are published near start time.
  final List<String> questionUuids;

  final int? participantCount;

  /// Live lobby presence (incremented when users enter lobby).
  final int? lobbyCount;

  /// Tomorrow's teaser topics (written when tonight is generated / closed).
  final List<DailyWarTopicRef> nextTopics;

  final int? rankedAtMs;

  bool get isGrand => kind == 'grand';

  bool get questionsVisible =>
      questionUuids.isNotEmpty &&
      (status == 'questions_published' ||
          status == 'closed' ||
          status == 'ranked');

  bool get ranksReady => status == 'ranked';

  factory DailyWarDoc.fromMap(String dateId, Map<String, dynamic> map) {
    List<DailyWarTopicRef> parseTopics(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => DailyWarTopicRef.fromMap(Map<String, dynamic>.from(e)))
          .where((t) => t.subjectSlug.isNotEmpty && t.topic.isNotEmpty)
          .toList();
    }

    final uuidsRaw = map['question_uuids'];
    final uuids = uuidsRaw is List
        ? uuidsRaw.whereType<String>().toList()
        : const <String>[];

    return DailyWarDoc(
      dateId: dateId,
      kind: (map['kind'] as String? ?? 'daily').trim(),
      topics: parseTopics(map['topics']),
      questionCount: (map['question_count'] as num?)?.toInt() ??
          (map['kind'] == 'grand' ? 25 : 15),
      status: (map['status'] as String? ?? 'announced').trim(),
      questionUuids: uuids,
      participantCount: (map['participant_count'] as num?)?.toInt(),
      lobbyCount: (map['lobby_count'] as num?)?.toInt(),
      nextTopics: parseTopics(map['next_topics']),
      rankedAtMs: (map['ranked_at_ms'] as num?)?.toInt(),
    );
  }
}

/// A user's submission under `daily_wars/{dateId}/submissions/{uid}`.
class DailyWarSubmission {
  const DailyWarSubmission({
    required this.uid,
    required this.mode,
    required this.score,
    required this.correct,
    required this.wrong,
    required this.unanswered,
    required this.elapsedMs,
    this.air,
    this.percentile,
    this.displayName,
  });

  final String uid;

  /// `live` or `unranked`.
  final String mode;
  final double score;
  final int correct;
  final int wrong;
  final int unanswered;
  final int elapsedMs;
  final int? air;
  final double? percentile;
  final String? displayName;

  bool get isLive => mode == 'live';
  bool get hasOfficialRank => isLive && air != null;

  factory DailyWarSubmission.fromMap(String uid, Map<String, dynamic> map) {
    return DailyWarSubmission(
      uid: uid,
      mode: (map['mode'] as String? ?? 'live').trim(),
      score: (map['score'] as num?)?.toDouble() ?? 0,
      correct: (map['correct'] as num?)?.toInt() ?? 0,
      wrong: (map['wrong'] as num?)?.toInt() ?? 0,
      unanswered: (map['unanswered'] as num?)?.toInt() ?? 0,
      elapsedMs: (map['elapsed_ms'] as num?)?.toInt() ?? 0,
      air: (map['air'] as num?)?.toInt(),
      percentile: (map['percentile'] as num?)?.toDouble(),
      displayName: map['display_name'] as String?,
    );
  }
}
