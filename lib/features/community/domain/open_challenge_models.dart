import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';

class OpenChallengeProfileSnapshot {
  const OpenChallengeProfileSnapshot({
    required this.email,
    required this.name,
    required this.photoUrl,
    this.telegram,
    this.instagram,
    this.status,
  });

  final String email;
  final String name;
  final String photoUrl;
  final String? telegram;
  final String? instagram;
  final String? status;

  Map<String, dynamic> toFirestoreMap() => {
    'email': email,
    'name': name,
    'photoURL': photoUrl,
    if (telegram != null) 'telegram': telegram,
    if (instagram != null) 'insta': instagram,
    if (status != null) 'my_status': status,
  };

  /// [attemptFieldKey] is the Firestore document field name for this attempt
  /// (lowercased email). Used when nested `profile.email` is missing or legacy
  /// clients wrote an incomplete profile map — otherwise the whole row is dropped.
  static OpenChallengeProfileSnapshot? fromMap(
    Map<String, dynamic>? m, {
    String? attemptFieldKey,
  }) {
    final keyFallback = attemptFieldKey?.toLowerCase().trim();
    if (m == null || m.isEmpty) {
      if (keyFallback == null || keyFallback.isEmpty) return null;
      return OpenChallengeProfileSnapshot(
        email: keyFallback,
        name: _displayNameFromEmailKey(keyFallback),
        photoUrl: '',
        telegram: null,
        instagram: null,
        status: null,
      );
    }
    var email = _nonEmptyString(m['email'])?.toLowerCase() ?? '';
    if (email.isEmpty && keyFallback != null) email = keyFallback;
    if (email.isEmpty) return null;

    final nameRaw = _nonEmptyString(m['name']);
    final name = (nameRaw != null && nameRaw.isNotEmpty)
        ? nameRaw
        : _displayNameFromEmailKey(email);

    final photo =
        _nonEmptyString(m['photoURL']) ?? _nonEmptyString(m['photoUrl']);
    return OpenChallengeProfileSnapshot(
      email: email,
      name: name,
      photoUrl: AppConstants.customProfilePhotoUrl(photo),
      telegram: _nonEmptyString(m['telegram']),
      instagram: _nonEmptyString(m['insta']) ?? _nonEmptyString(m['instagram']),
      status: _nonEmptyString(m['my_status']) ?? _nonEmptyString(m['status']),
    );
  }
}

class OpenChallengeAttemptEntry {
  const OpenChallengeAttemptEntry({
    required this.emailKey,
    required this.profile,
    required this.attemptsByQuestionUuid,
    required this.score,
    required this.attemptedAt,
    this.reviewSessionId,
  });

  final String emailKey;
  final OpenChallengeProfileSnapshot profile;
  final Map<String, String> attemptsByQuestionUuid;
  final int score;
  final DateTime attemptedAt;

  /// Local SQLite session id for post-test explanation review (same device).
  final String? reviewSessionId;
}

class OpenChallengeDetail {
  const OpenChallengeDetail({
    required this.id,
    required this.subject,
    required this.questionUuids,
    required this.createdAt,
    required this.expiresAt,
    required this.attemptsByEmail,
  });

  final String id;
  final String subject;
  final List<String> questionUuids;
  final DateTime? createdAt;

  /// When absent in Firestore, treated as [createdAt] + 24h for legacy docs.
  final DateTime? expiresAt;
  final Map<String, OpenChallengeAttemptEntry> attemptsByEmail;

  DateTime? get effectiveExpiresAt =>
      expiresAt ?? (createdAt?.add(const Duration(hours: 24)));

  bool get isExpired {
    final end = effectiveExpiresAt;
    if (end == null) return false;
    return DateTime.now().isAfter(end);
  }

  OpenChallengeAttemptEntry? creatorEntry() {
    OpenChallengeAttemptEntry? best;
    for (final e in attemptsByEmail.values) {
      if (best == null || e.attemptedAt.isBefore(best.attemptedAt)) {
        best = e;
      }
    }
    return best;
  }

  List<OpenChallengeLeaderboardRow> leaderboardRows() {
    final rows = attemptsByEmail.values
        .map(
          (e) => OpenChallengeLeaderboardRow(
            profile: e.profile,
            score: e.score,
            attemptedAt: e.attemptedAt,
          ),
        )
        .toList();
    rows.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.attemptedAt.compareTo(b.attemptedAt);
    });
    return rows;
  }

  /// True if [data] already includes an attempt for this participant.
  ///
  /// Firestore treats `.` in [Transaction.update] map keys as nested paths, so
  /// older accepts may have stored the payload under nested maps instead of a
  /// single top-level field named like the email. This walks those shapes too.
  static bool documentContainsParticipantAttempt(
    Map<String, dynamic> data,
    String participantEmailLower,
  ) {
    final t = participantEmailLower.toLowerCase().trim();
    if (t.isEmpty) return false;
    for (final key in data.keys) {
      if (_openChallengeReservedRootKey(key)) continue;
      if (key.toLowerCase() == t && data[key] is Map) {
        final m = Map<String, dynamic>.from(data[key]! as Map);
        if (_scoreFromFirestoreAttempt(m) != null) return true;
      }
    }
    bool walk(Map<String, dynamic> map) {
      if (_scoreFromFirestoreAttempt(map) != null) {
        final raw = map['profile'];
        if (raw is Map) {
          final p = OpenChallengeProfileSnapshot.fromMap(
            Map<String, dynamic>.from(raw),
            attemptFieldKey: null,
          );
          if (p != null && p.email.toLowerCase() == t) return true;
        }
      }
      for (final v in map.values) {
        if (v is Map && walk(Map<String, dynamic>.from(v))) return true;
      }
      return false;
    }

    for (final e in data.entries) {
      if (_openChallengeReservedRootKey(e.key)) continue;
      final v = e.value;
      if (v is Map && walk(Map<String, dynamic>.from(v))) return true;
    }
    return false;
  }

  static OpenChallengeDetail? parse(String id, Map<String, dynamic> data) {
    if (kDebugMode) {
      final keySummary = data.keys
          .map((k) {
            final v = data[k];
            return '$k:${v.runtimeType}';
          })
          .join(', ');
      debugPrint('[OpenChallenge:parse] doc=$id rootKeys($keySummary)');
    }

    final questionsRaw = data['questions'];
    if (questionsRaw is! List) {
      _openChallengeParseLog(
        'doc=$id FAIL questions is ${questionsRaw.runtimeType}, need List',
      );
      return null;
    }
    final uuids = questionsRaw.map((e) => '$e').toList();
    if (uuids.length != 10) {
      _openChallengeParseLog(
        'doc=$id FAIL questions.length=${uuids.length} (need 10)',
      );
      return null;
    }
    final subject = (data['subject'] as String?)?.trim() ?? '';
    if (subject.isEmpty) {
      _openChallengeParseLog('doc=$id FAIL subject empty or missing');
      return null;
    }

    final createdAt = _readDateTime(data['created_at']);
    final expiresAt = _readDateTime(data['expires_at']);

    final attempts = <String, OpenChallengeAttemptEntry>{};
    for (final e in data.entries) {
      if (_openChallengeReservedRootKey(e.key)) continue;
      final v = e.value;
      if (v is! Map) {
        _openChallengeParseLog(
          'doc=$id skip field="${e.key}" valueType=${v.runtimeType} (need Map for attempt)',
        );
        continue;
      }
      _walkOpenChallengeAttemptMaps(
        docId: id,
        rootFieldKey: e.key,
        node: v,
        createdAt: createdAt,
        attempts: attempts,
      );
    }
    if (kDebugMode) {
      debugPrint(
        '[OpenChallenge:parse] doc=$id DONE attempts=${attempts.length} '
        'emails=${attempts.keys.toList()..sort()}',
      );
    }
    return OpenChallengeDetail(
      id: id,
      subject: subject,
      questionUuids: uuids,
      createdAt: createdAt,
      expiresAt: expiresAt,
      attemptsByEmail: attempts,
    );
  }
}

class OpenChallengeLeaderboardRow {
  const OpenChallengeLeaderboardRow({
    required this.profile,
    required this.score,
    required this.attemptedAt,
  });

  final OpenChallengeProfileSnapshot profile;
  final int score;
  final DateTime attemptedAt;
}

bool _openChallengeReservedRootKey(String k) =>
    k == 'questions' ||
    k == 'subject' ||
    k == 'created_at' ||
    k == 'expires_at';

/// Firestore [Transaction.update] treats `.` in String keys as nested field
/// paths. Walk [node] until we find a leaf map that looks like an attempt
/// payload (`score` + optional `profile`), then merge into [attempts].
void _walkOpenChallengeAttemptMaps({
  required String docId,
  required String rootFieldKey,
  required dynamic node,
  required DateTime? createdAt,
  required Map<String, OpenChallengeAttemptEntry> attempts,
  int depth = 0,
}) {
  if (depth > 16) return;
  if (node is! Map) return;
  final map = Map<String, dynamic>.from(node);
  if (_scoreFromFirestoreAttempt(map) != null) {
    _mergeAttemptMapIfValid(
      docId: docId,
      fieldHint: rootFieldKey,
      map: map,
      createdAt: createdAt,
      attempts: attempts,
      nested: depth > 0,
    );
    return;
  }
  for (final e in map.entries) {
    _walkOpenChallengeAttemptMaps(
      docId: docId,
      rootFieldKey: '$rootFieldKey.${e.key}',
      node: e.value,
      createdAt: createdAt,
      attempts: attempts,
      depth: depth + 1,
    );
  }
}

void _mergeAttemptMapIfValid({
  required String docId,
  required String fieldHint,
  required Map<String, dynamic> map,
  required DateTime? createdAt,
  required Map<String, OpenChallengeAttemptEntry> attempts,
  required bool nested,
}) {
  Map<String, dynamic>? profileMap;
  final rawProfile = map['profile'];
  if (rawProfile is Map) {
    profileMap = Map<String, dynamic>.from(rawProfile);
  }
  final profile = OpenChallengeProfileSnapshot.fromMap(
    profileMap,
    attemptFieldKey: fieldHint,
  );
  if (profile == null) {
    _openChallengeParseLog(
      'doc=$docId skip fieldHint="$fieldHint" profile=null '
      '(rawProfileType=${rawProfile.runtimeType}, mapKeys=${map.keys.toList()})',
    );
    return;
  }
  final attemptsMap = (map['attempts'] as Map?)?.cast<dynamic, dynamic>();
  final byQ = <String, String>{};
  if (attemptsMap != null) {
    for (final a in attemptsMap.entries) {
      byQ['${a.key}'] = '${a.value}'.toLowerCase().trim();
    }
  }
  final score = _scoreFromFirestoreAttempt(map);
  if (score == null) {
    final raw = map['score'];
    _openChallengeParseLog(
      'doc=$docId skip fieldHint="$fieldHint" score unreadable '
      'raw=$raw (${raw.runtimeType})',
    );
    return;
  }
  final at =
      _readDateTime(map['attempted_at']) ?? createdAt ?? DateTime.now().toUtc();
  final rsRaw = map['review_session_id'];
  final reviewSessionId = rsRaw is String && rsRaw.trim().isNotEmpty
      ? rsRaw.trim()
      : null;
  final emailKey = profile.email.toLowerCase();
  attempts[emailKey] = OpenChallengeAttemptEntry(
    emailKey: emailKey,
    profile: profile,
    attemptsByQuestionUuid: byQ,
    score: score,
    attemptedAt: at,
    reviewSessionId: reviewSessionId,
  );
  _openChallengeParseLog(
    'doc=$docId OK attempt emailKey="$emailKey" score=$score '
    'profile.email=${profile.email} name=${profile.name} '
    'byQCount=${byQ.length} nested=$nested fieldHint="$fieldHint" '
    'attempted_at=${map['attempted_at']?.runtimeType ?? 'missing'}',
  );
}

class OpenChallengeListTileModel {
  const OpenChallengeListTileModel({
    required this.id,
    required this.subject,
    required this.attemptCount,
    required this.topScore,
    this.myScore,
    required this.postedByName,
    this.postedByEmail,
    required this.postedByPhotoUrl,
    required this.postedAt,
    required this.liveUntil,
  });

  final String id;
  final String subject;
  final int attemptCount;
  final int topScore;
  final int? myScore;
  final String postedByName;

  /// Lowercased email of the creator (for "You" vs name in the list UI).
  final String? postedByEmail;
  final String postedByPhotoUrl;
  final DateTime? postedAt;

  /// When the challenge stops accepting attempts (24h window).
  final DateTime? liveUntil;
}

void _openChallengeParseLog(String message) {
  if (kDebugMode) {
    debugPrint('[OpenChallenge:parse] $message');
  }
}

DateTime? _readDateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
  }
  return null;
}

String? _nonEmptyString(Object? value) {
  if (value == null) return null;
  if (value is String) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }
  final t = value.toString().trim();
  return t.isEmpty ? null : t;
}

String _displayNameFromEmailKey(String emailLower) {
  final at = emailLower.indexOf('@');
  if (at > 0) {
    final local = emailLower.substring(0, at).trim();
    if (local.isNotEmpty) return local;
  }
  return 'UPSC Warrior';
}

int? _scoreFromFirestoreAttempt(Map<String, dynamic> map) {
  final s = map['score'];
  if (s is num) return s.toInt();
  if (s is String) return int.tryParse(s.trim());
  return null;
}
