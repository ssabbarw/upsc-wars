/// A user's submission under `daily_ca_days/{dateId}/submissions/{uid}`.
class DailyCaSubmission {
  const DailyCaSubmission({
    required this.uid,
    required this.mode,
    required this.score,
    required this.correct,
    required this.wrong,
    required this.unanswered,
    required this.elapsedMs,
    this.air,
    this.percentile,
    this.participantCount,
    this.displayName,
    this.email,
    this.submittedAtMs,
  });

  final String uid;

  /// `live` (ranked) or `unranked` (after freeze / past paper).
  final String mode;
  final double score;
  final int correct;
  final int wrong;
  final int unanswered;
  final int elapsedMs;
  final int? air;
  final double? percentile;
  final int? participantCount;
  final String? displayName;
  final String? email;
  final int? submittedAtMs;

  bool get isLive => mode == 'live';
  bool get hasOfficialRank => isLive && air != null;

  factory DailyCaSubmission.fromMap(String uid, Map<String, dynamic> map) {
    return DailyCaSubmission(
      uid: uid,
      mode: (map['mode'] as String? ?? 'live').trim(),
      score: (map['score'] as num?)?.toDouble() ?? 0,
      correct: (map['correct'] as num?)?.toInt() ?? 0,
      wrong: (map['wrong'] as num?)?.toInt() ?? 0,
      unanswered: (map['unanswered'] as num?)?.toInt() ?? 0,
      elapsedMs: (map['elapsed_ms'] as num?)?.toInt() ?? 0,
      air: (map['air'] as num?)?.toInt(),
      percentile: (map['percentile'] as num?)?.toDouble(),
      participantCount: (map['participant_count'] as num?)?.toInt(),
      displayName: map['display_name'] as String?,
      email: (map['email'] as String?)?.trim().toLowerCase(),
      submittedAtMs: (map['submitted_at_ms'] as num?)?.toInt(),
    );
  }
}

class DailyCaLeaderboardEntry {
  const DailyCaLeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.score,
    required this.elapsedMs,
    required this.air,
    this.percentile,
    this.correct,
    this.wrong,
    this.unanswered,
    this.email,
  });

  final String uid;
  final String displayName;
  final double score;
  final int elapsedMs;
  final int air;
  final double? percentile;
  final int? correct;
  final int? wrong;
  final int? unanswered;
  final String? email;

  factory DailyCaLeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return DailyCaLeaderboardEntry(
      uid: '${map['uid'] ?? ''}',
      displayName: (map['display_name'] as String? ?? '').trim(),
      score: (map['score'] as num?)?.toDouble() ?? 0,
      elapsedMs: (map['elapsed_ms'] as num?)?.toInt() ?? 0,
      air: (map['air'] as num?)?.toInt() ?? 0,
      percentile: (map['percentile'] as num?)?.toDouble(),
      correct: (map['correct'] as num?)?.toInt(),
      wrong: (map['wrong'] as num?)?.toInt(),
      unanswered: (map['unanswered'] as num?)?.toInt(),
      email: (map['email'] as String?)?.trim().toLowerCase(),
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'display_name': displayName,
    'score': score,
    'elapsed_ms': elapsedMs,
    'air': air,
    if (percentile != null) 'percentile': percentile,
    if (correct != null) 'correct': correct,
    if (wrong != null) 'wrong': wrong,
    if (unanswered != null) 'unanswered': unanswered,
    if (email != null && email!.isNotEmpty) 'email': email,
  };
}

class DailyCaLeaderboard {
  const DailyCaLeaderboard({
    required this.dateId,
    required this.top,
    required this.participantCount,
    this.questionCount = 0,
    this.status = 'live',
  });

  final String dateId;
  final List<DailyCaLeaderboardEntry> top;
  final int participantCount;
  final int questionCount;
  final String status;

  bool get isFrozen => status == 'frozen';

  factory DailyCaLeaderboard.fromMap(String dateId, Map<String, dynamic> map) {
    final topRaw = map['top'];
    final top = <DailyCaLeaderboardEntry>[];
    if (topRaw is List) {
      for (final e in topRaw) {
        if (e is Map) {
          top.add(
            DailyCaLeaderboardEntry.fromMap(Map<String, dynamic>.from(e)),
          );
        }
      }
    }
    return DailyCaLeaderboard(
      dateId: dateId,
      top: top,
      participantCount:
          (map['participant_count'] as num?)?.toInt() ?? top.length,
      questionCount: (map['question_count'] as num?)?.toInt() ?? 0,
      status: (map['status'] as String? ?? 'live').trim(),
    );
  }

  Map<String, dynamic> toCacheMap() => {
    'date_id': dateId,
    'top': top.map((e) => e.toMap()).toList(),
    'participant_count': participantCount,
    'question_count': questionCount,
    'status': status,
  };
}
