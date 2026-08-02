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

  /// True once the paper is final for archive purposes (safe to keep forever).
  bool get isStableArchive =>
      status == 'ranked' ||
      (status == 'closed' && questionUuids.isNotEmpty);

  Map<String, dynamic> toCacheMap() => {
        'date_id': dateId,
        'kind': kind,
        'topics': topics.map((t) => t.toMap()).toList(),
        'question_count': questionCount,
        'status': status,
        'question_uuids': questionUuids,
        if (participantCount != null) 'participant_count': participantCount,
        if (lobbyCount != null) 'lobby_count': lobbyCount,
        'next_topics': nextTopics.map((t) => t.toMap()).toList(),
        if (rankedAtMs != null) 'ranked_at_ms': rankedAtMs,
      };

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
    this.answers = const {},
    this.streakDays = 0,
    this.tierId,
    this.badges = const [],
    this.submittedAtMs,
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

  /// `questionUuid` → selected option letter (`a`/`b`/`c`/`d`).
  final Map<String, String> answers;

  final int streakDays;
  final String? tierId;
  final List<String> badges;
  final int? submittedAtMs;

  bool get isLive => mode == 'live';
  bool get hasOfficialRank => isLive && air != null;

  Map<String, dynamic> toCacheMap() => {
        'uid': uid,
        'mode': mode,
        'score': score,
        'correct': correct,
        'wrong': wrong,
        'unanswered': unanswered,
        'elapsed_ms': elapsedMs,
        if (air != null) 'air': air,
        if (percentile != null) 'percentile': percentile,
        if (displayName != null) 'display_name': displayName,
        'answers': answers,
        'streak_days': streakDays,
        if (tierId != null) 'tier_id': tierId,
        'badges': badges,
        if (submittedAtMs != null) 'submitted_at_ms': submittedAtMs,
      };

  factory DailyWarSubmission.fromMap(String uid, Map<String, dynamic> map) {
    final answersRaw = map['answers'];
    final answers = <String, String>{};
    if (answersRaw is Map) {
      for (final e in answersRaw.entries) {
        final k = '${e.key}'.trim();
        final v = '${e.value}'.trim().toLowerCase();
        if (k.isNotEmpty && v.isNotEmpty) answers[k] = v;
      }
    }
    final badgesRaw = map['badges'];
    final badges = badgesRaw is List
        ? badgesRaw.map((e) => '$e').where((s) => s.isNotEmpty).toList()
        : const <String>[];

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
      answers: answers,
      streakDays: (map['streak_days'] as num?)?.toInt() ?? 0,
      tierId: (map['tier_id'] as String?)?.trim(),
      badges: badges,
      submittedAtMs: (map['submitted_at_ms'] as num?)?.toInt(),
    );
  }
}

/// One row on `daily_wars/{dateId}/meta/leaderboard`.
class DailyWarLeaderboardEntry {
  const DailyWarLeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.score,
    required this.elapsedMs,
    required this.air,
    this.percentile,
    this.streakDays = 0,
    this.tierId,
    this.badges = const [],
  });

  final String uid;
  final String displayName;
  final double score;
  final int elapsedMs;
  final int air;
  final double? percentile;

  /// Consistency days at submit time (badge ladder).
  final int streakDays;

  /// `recruit` … `marshal`, or null.
  final String? tierId;

  /// Night award ids + optionally the tier id for icon chips.
  final List<String> badges;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'display_name': displayName,
        'score': score,
        'elapsed_ms': elapsedMs,
        'air': air,
        if (percentile != null) 'percentile': percentile,
        'streak_days': streakDays,
        if (tierId != null) 'tier_id': tierId,
        'badges': badges,
      };

  factory DailyWarLeaderboardEntry.fromMap(Map<String, dynamic> map) {
    final badgesRaw = map['badges'];
    final badges = badgesRaw is List
        ? badgesRaw.map((e) => '$e').where((s) => s.isNotEmpty).toList()
        : const <String>[];
    return DailyWarLeaderboardEntry(
      uid: '${map['uid'] ?? ''}',
      displayName: (map['display_name'] as String? ?? '').trim(),
      score: (map['score'] as num?)?.toDouble() ?? 0,
      elapsedMs: (map['elapsed_ms'] as num?)?.toInt() ?? 0,
      air: (map['air'] as num?)?.toInt() ?? 0,
      percentile: (map['percentile'] as num?)?.toDouble(),
      streakDays: (map['streak_days'] as num?)?.toInt() ?? 0,
      tierId: (map['tier_id'] as String?)?.trim(),
      badges: badges,
    );
  }
}

/// Cached leaderboard snapshot for a War night.
class DailyWarLeaderboard {
  const DailyWarLeaderboard({
    required this.dateId,
    required this.top,
    required this.participantCount,
  });

  final String dateId;
  final List<DailyWarLeaderboardEntry> top;
  final int participantCount;

  Map<String, dynamic> toCacheMap() => {
        'date_id': dateId,
        'top': top.map((e) => e.toMap()).toList(),
        'participant_count': participantCount,
      };

  factory DailyWarLeaderboard.fromMap(String dateId, Map<String, dynamic> map) {
    final topRaw = map['top'];
    final top = <DailyWarLeaderboardEntry>[];
    if (topRaw is List) {
      for (final e in topRaw) {
        if (e is Map) {
          top.add(
            DailyWarLeaderboardEntry.fromMap(Map<String, dynamic>.from(e)),
          );
        }
      }
    }
    return DailyWarLeaderboard(
      dateId: dateId,
      top: top,
      participantCount: (map['participant_count'] as num?)?.toInt() ?? top.length,
    );
  }
}
