import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../database/user_db.dart';

/// Wire format of one backed-up test attempt
/// (`user_backups/{uid}/sessions/{sessionId}`).
///
/// One document per completed session keeps backup at **one write per submit**
/// and restore at one read per attempt. A 100-question attempt is ~10 KB, far
/// under Firestore's 1 MiB limit. Question text is never stored — the bank is
/// local — only the UUIDs and what the learner did.
abstract final class SessionBackupFormat {
  static const collectionName = 'user_backups';
  static const sessionsSubcollection = 'sessions';
  static const schemaVersion = 1;

  /// Safety valve: a single doc must stay well under 1 MiB.
  static const maxQuestionsPerDoc = 2000;

  // Session-level keys.
  static const v = 'v';
  static const sid = 'sid';
  static const createdAtMs = 'createdAtMs';
  static const completedAtMs = 'completedAtMs';
  static const subject = 'subject';
  static const topic = 'topic';
  static const subTopic = 'subTopic';
  static const mode = 'mode';
  static const questionCount = 'qc';
  static const score = 'score';
  static const isTimed = 'timed';
  static const timeLimitSecs = 'limitSecs';
  static const language = 'lang';
  static const featureKey = 'fk';
  static const seriesId = 'seriesId';
  static const seriesTestId = 'seriesTestId';
  static const questions = 'q';
  static const backedUpAt = 'backedUpAt';

  // Per-question keys (kept short; there can be 100+ per doc).
  static const qUuid = 'u';
  static const qSelected = 's';
  static const qCorrect = 'c';
  static const qStatus = 'st';
  static const qTime = 't';
  static const qFlagged = 'f';
  static const qAttemptedMs = 'at';
  static const qConfidence = 'cf';

  /// Daily CA date of a question; lets restore re-fetch CA questions that are
  /// not in the freshly installed local bank.
  static const qCaDate = 'd';
}

/// A session decoded from a backup doc, ready to insert locally.
class RestoredSession {
  const RestoredSession({
    required this.session,
    required this.attempts,
    this.caDatesByUuid = const {},
  });

  final SessionsCompanion session;
  final List<SessionQuestionsCompanion> attempts;

  /// Daily CA dates keyed by question uuid (only for CA questions).
  final Map<String, String> caDatesByUuid;

  String get id => session.id.value;
}

abstract final class SessionBackupCodec {
  static const _uuid = Uuid();

  /// Builds the Firestore payload for [session] and its [attempts].
  ///
  /// [caDates] maps question uuid → Daily CA date for CA questions.
  /// Returns null when the session is too large to back up safely.
  static Map<String, dynamic>? encode({
    required Session session,
    required List<SessionQuestion> attempts,
    Map<String, String> caDates = const {},
  }) {
    if (attempts.length > SessionBackupFormat.maxQuestionsPerDoc) return null;
    final completedAt = session.completedAt ?? session.createdAt;
    return {
      SessionBackupFormat.v: SessionBackupFormat.schemaVersion,
      SessionBackupFormat.sid: session.id,
      SessionBackupFormat.createdAtMs: session.createdAt.millisecondsSinceEpoch,
      SessionBackupFormat.completedAtMs: completedAt.millisecondsSinceEpoch,
      SessionBackupFormat.subject: session.subject,
      if (session.topic != null) SessionBackupFormat.topic: session.topic,
      if (session.subTopic != null)
        SessionBackupFormat.subTopic: session.subTopic,
      SessionBackupFormat.mode: session.mode,
      SessionBackupFormat.questionCount: session.questionCount,
      if (session.score != null) SessionBackupFormat.score: session.score,
      SessionBackupFormat.isTimed: session.isTimed,
      if (session.timeLimitSecs != null)
        SessionBackupFormat.timeLimitSecs: session.timeLimitSecs,
      SessionBackupFormat.language: session.language,
      if (session.analyticsFeatureKey != null)
        SessionBackupFormat.featureKey: session.analyticsFeatureKey,
      if (session.seriesId != null)
        SessionBackupFormat.seriesId: session.seriesId,
      if (session.seriesTestId != null)
        SessionBackupFormat.seriesTestId: session.seriesTestId,
      SessionBackupFormat.questions: [
        for (final a in attempts)
          {
            SessionBackupFormat.qUuid: a.questionUuid,
            if (a.selectedOption != null)
              SessionBackupFormat.qSelected: a.selectedOption,
            if (a.isCorrect != null)
              SessionBackupFormat.qCorrect: a.isCorrect! ? 1 : 0,
            SessionBackupFormat.qStatus: a.status,
            if (a.timeSpentSecs != null)
              SessionBackupFormat.qTime: a.timeSpentSecs,
            if (a.flagged) SessionBackupFormat.qFlagged: 1,
            if (a.attemptedAt != null)
              SessionBackupFormat.qAttemptedMs:
                  a.attemptedAt!.millisecondsSinceEpoch,
            if (a.confidence != null)
              SessionBackupFormat.qConfidence: a.confidence,
            if (caDates[a.questionUuid] != null)
              SessionBackupFormat.qCaDate: caDates[a.questionUuid],
          },
      ],
    };
  }

  /// Decodes a backup doc; returns null if it is malformed or from a newer,
  /// unknown schema.
  static RestoredSession? decode(Map<String, dynamic> data, {DateTime? now}) {
    try {
      final version = (data[SessionBackupFormat.v] as num?)?.toInt() ?? 0;
      if (version < 1 || version > SessionBackupFormat.schemaVersion) {
        return null;
      }
      final id = data[SessionBackupFormat.sid] as String?;
      final rawQ = data[SessionBackupFormat.questions];
      if (id == null || id.isEmpty || rawQ is! List || rawQ.isEmpty) {
        return null;
      }
      final stamp = now ?? DateTime.now();
      DateTime ms(Object? v) =>
          DateTime.fromMillisecondsSinceEpoch((v as num).toInt());

      final session = SessionsCompanion.insert(
        id: id,
        createdAt: ms(data[SessionBackupFormat.createdAtMs]),
        completedAt: Value(ms(data[SessionBackupFormat.completedAtMs])),
        subject: data[SessionBackupFormat.subject] as String,
        topic: Value(data[SessionBackupFormat.topic] as String?),
        subTopic: Value(data[SessionBackupFormat.subTopic] as String?),
        mode: data[SessionBackupFormat.mode] as String,
        status: 'completed',
        questionCount: (data[SessionBackupFormat.questionCount] as num).toInt(),
        score: Value((data[SessionBackupFormat.score] as num?)?.toInt()),
        isTimed: data[SessionBackupFormat.isTimed] as bool? ?? false,
        timeLimitSecs: Value(
          (data[SessionBackupFormat.timeLimitSecs] as num?)?.toInt(),
        ),
        language: Value(data[SessionBackupFormat.language] as String? ?? 'en'),
        analyticsFeatureKey: Value(
          data[SessionBackupFormat.featureKey] as String?,
        ),
        seriesId: Value(data[SessionBackupFormat.seriesId] as String?),
        seriesTestId: Value(data[SessionBackupFormat.seriesTestId] as String?),
        // Already counted in global question stats when first submitted;
        // never re-aggregate a restored session.
        synced: const Value(true),
        backedUpAt: Value(stamp),
      );

      final attempts = <SessionQuestionsCompanion>[];
      final caDates = <String, String>{};
      for (var i = 0; i < rawQ.length; i++) {
        final q = Map<String, dynamic>.from(rawQ[i] as Map);
        final uuid = q[SessionBackupFormat.qUuid] as String;
        final correct = q[SessionBackupFormat.qCorrect] as num?;
        final attemptedMs = q[SessionBackupFormat.qAttemptedMs] as num?;
        attempts.add(
          SessionQuestionsCompanion.insert(
            id: _uuid.v4(),
            sessionId: id,
            questionUuid: uuid,
            position: i + 1,
            selectedOption: Value(q[SessionBackupFormat.qSelected] as String?),
            isCorrect: Value(correct == null ? null : correct != 0),
            status: Value(
              q[SessionBackupFormat.qStatus] as String? ?? 'unattempted',
            ),
            timeSpentSecs: Value(
              (q[SessionBackupFormat.qTime] as num?)?.toInt(),
            ),
            flagged: Value(
              ((q[SessionBackupFormat.qFlagged] as num?) ?? 0) != 0,
            ),
            attemptedAt: Value(attemptedMs == null ? null : ms(attemptedMs)),
            confidence: Value(q[SessionBackupFormat.qConfidence] as String?),
          ),
        );
        final d = q[SessionBackupFormat.qCaDate] as String?;
        if (d != null && d.isNotEmpty) caDates[uuid] = d;
      }
      return RestoredSession(
        session: session,
        attempts: attempts,
        caDatesByUuid: caDates,
      );
    } catch (_) {
      return null;
    }
  }
}
