import 'package:cloud_firestore/cloud_firestore.dart';

import 'qotd_reactions.dart';

/// Community QOTD posts are visible for this long after [createdAt].
const Duration kQotdPostLiveDuration = Duration(hours: 24);

/// Thrown when this device has hit the local rolling-window QOTD cap (Remote Config).
class QotdDailyLimitExceeded implements Exception {
  const QotdDailyLimitExceeded(this.maxPerWindow);
  final int maxPerWindow;

  @override
  String toString() =>
      'Posting more than $maxPerWindow QOTD is not allowed in a 24-hour window right now';
}

class QotdPost {
  const QotdPost({
    required this.id,
    required this.questionUuid,
    required this.comment,
    required this.authorEmail,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.createdAt,
    required this.correctOption,
    required this.correctCount,
    required this.wrongCount,
    required this.reactionCounts,
  });

  final String id;
  final String questionUuid;
  final String comment;
  final String authorEmail;
  final String authorName;
  final String authorPhotoUrl;
  final DateTime? createdAt;
  final String correctOption;
  final int correctCount;
  final int wrongCount;
  final Map<String, int> reactionCounts;

  /// When this post leaves the active QOTD window (`createdAt` + 24h).
  DateTime? get liveUntil {
    final c = createdAt;
    if (c == null) return null;
    return c.add(kQotdPostLiveDuration);
  }

  /// Whether the 24-hour window has passed (no [createdAt] → not expired).
  bool get isExpired {
    final end = liveUntil;
    if (end == null) return false;
    return !DateTime.now().isBefore(end);
  }

  static QotdPost? parse(String id, Map<String, dynamic> data) {
    final qUuid = (data['question_uuid'] as String?)?.trim();
    final comment = (data['comment'] as String?)?.trim() ?? '';
    final authorEmail = (data['author_email'] as String?)?.toLowerCase().trim() ?? '';
    final authorName = (data['author_name'] as String?)?.trim() ?? '';
    final authorPhotoUrl = (data['author_photo_url'] as String?)?.trim() ?? '';
    final correctOpt = (data['correct_option'] as String?)?.toLowerCase().trim() ?? '';
    if (qUuid == null ||
        qUuid.isEmpty ||
        authorEmail.isEmpty ||
        authorName.isEmpty ||
        !{'a', 'b', 'c', 'd'}.contains(correctOpt)) {
      return null;
    }
    final created = data['created_at'];
    DateTime? createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    }
    final reactionsRaw = data['reaction_counts'];
    final reactionCounts = <String, int>{};
    if (reactionsRaw is Map) {
      for (final e in reactionsRaw.entries) {
        final k = e.key.toString();
        final v = e.value;
        final n = v is int ? v : int.tryParse(v.toString()) ?? 0;
        // Only canonical ids (legacy emoji-key tallies are ignored).
        if (k.isNotEmpty && n > 0 && qotdReactionIds.contains(k)) {
          reactionCounts[k] = n;
        }
      }
    }
    return QotdPost(
      id: id,
      questionUuid: qUuid,
      comment: comment,
      authorEmail: authorEmail,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      createdAt: createdAt,
      correctOption: correctOpt,
      correctCount: (data['correct_count'] as num?)?.toInt() ?? 0,
      wrongCount: (data['wrong_count'] as num?)?.toInt() ?? 0,
      reactionCounts: reactionCounts,
    );
  }
}

/// One reader's MCQ pick stored inline on the QOTD doc (`qotd_posts/{postId}.attempts[uid]`).
class QotdAttemptEntry {
  const QotdAttemptEntry({
    required this.uid,
    required this.pickedOption,
    required this.isCorrect,
    required this.attemptedAt,
    this.authorEmail,
    this.authorName,
    this.authorPhotoUrl,
  });

  final String uid;
  final String pickedOption;
  final bool isCorrect;
  final DateTime attemptedAt;
  final String? authorEmail;
  final String? authorName;
  final String? authorPhotoUrl;
}
