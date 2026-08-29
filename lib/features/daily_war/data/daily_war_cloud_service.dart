import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../daily_war_constants.dart';

class DailyWarSubmitResult {
  const DailyWarSubmitResult({
    required this.ok,
    this.score,
    this.correct,
    this.wrong,
    this.unanswered,
    this.mode,
    this.badges = const [],
    this.errorMessage,
    this.errorReason,
  });

  final bool ok;
  final double? score;
  final int? correct;
  final int? wrong;
  final int? unanswered;
  final String? mode;
  final List<String> badges;
  final String? errorMessage;

  /// Machine-readable `reason` from the function's error details, so callers
  /// don't have to match on message text.
  final String? errorReason;
}

/// Callable client for Daily War Cloud Functions (`asia-south1`).
class DailyWarCloudService {
  const DailyWarCloudService();

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: DailyWarConstants.functionsRegion);

  Future<DailyWarSubmitResult> submit({
    required String dateId,
    required Map<String, String> answers,
    required int elapsedMs,
    required String mode,
    String? displayName,
    int? warStreakDays,
    String? tierId,
  }) async {
    try {
      final callable = _functions.httpsCallable('submitDailyWar');
      final result = await callable.call<Map<String, dynamic>>({
        'dateId': dateId,
        'answers': answers,
        'elapsedMs': elapsedMs,
        'mode': mode,
        if (displayName != null && displayName.isNotEmpty)
          'displayName': displayName,
        if (warStreakDays != null) 'warStreakDays': warStreakDays,
        if (tierId != null && tierId.isNotEmpty) 'tierId': tierId,
      });
      final data = result.data;
      final badgesRaw = data['badges'];
      final badges = badgesRaw is List
          ? badgesRaw.map((e) => '$e').where((s) => s.isNotEmpty).toList()
          : const <String>[];
      return DailyWarSubmitResult(
        ok: data['ok'] == true,
        score: (data['score'] as num?)?.toDouble(),
        correct: (data['correct'] as num?)?.toInt(),
        wrong: (data['wrong'] as num?)?.toInt(),
        unanswered: (data['unanswered'] as num?)?.toInt(),
        mode: data['mode']?.toString(),
        badges: badges,
      );
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('DailyWarCloudService.submit: ${e.code} ${e.message}');
      debugPrintStack(stackTrace: st);
      final details = e.details;
      return DailyWarSubmitResult(
        ok: false,
        errorMessage: e.message ?? e.code,
        errorReason: details is Map ? details['reason']?.toString() : null,
      );
    } on Object catch (e, st) {
      debugPrint('DailyWarCloudService.submit: $e');
      debugPrintStack(stackTrace: st);
      return DailyWarSubmitResult(ok: false, errorMessage: e.toString());
    }
  }

  Future<bool> adminGenerate({
    required String dateId,
    bool force = false,
  }) async {
    try {
      final callable = _functions.httpsCallable('adminGenerateDailyWar');
      final result = await callable.call<Map<String, dynamic>>({
        'dateId': dateId,
        'force': force,
      });
      return result.data['ok'] == true;
    } on Object catch (e, st) {
      debugPrint('DailyWarCloudService.adminGenerate: $e');
      debugPrintStack(stackTrace: st);
      return false;
    }
  }

  /// Super-user preview of tonight's paper (private UUIDs before 20:59 publish).
  Future<DailyWarAdminPreview?> adminPreview({
    required String dateId,
    bool includeAnswers = false,
  }) async {
    try {
      final callable = _functions.httpsCallable('adminPreviewDailyWar');
      final result = await callable.call<Map<String, dynamic>>({
        'dateId': dateId,
        'includeAnswers': includeAnswers,
      });
      final data = result.data;
      if (data['ok'] != true) return null;
      return DailyWarAdminPreview.fromMap(Map<String, dynamic>.from(data));
    } on Object catch (e, st) {
      debugPrint('DailyWarCloudService.adminPreview: $e');
      debugPrintStack(stackTrace: st);
      return null;
    }
  }

  Future<bool> adminPublish({required String dateId}) async {
    try {
      final callable = _functions.httpsCallable('adminPublishDailyWar');
      final result = await callable.call<Map<String, dynamic>>({
        'dateId': dateId,
      });
      return result.data['ok'] == true;
    } on Object catch (e, st) {
      debugPrint('DailyWarCloudService.adminPublish: $e');
      debugPrintStack(stackTrace: st);
      return false;
    }
  }

  /// Force-send a Daily War FCM phase: morning | reminder_30 | lobby | results.
  Future<bool> adminNotify({
    required String dateId,
    required String phase,
  }) async {
    try {
      final callable = _functions.httpsCallable('adminNotifyDailyWar');
      final result = await callable.call<Map<String, dynamic>>({
        'dateId': dateId,
        'phase': phase,
      });
      return result.data['ok'] == true;
    } on Object catch (e, st) {
      debugPrint('DailyWarCloudService.adminNotify: $e');
      debugPrintStack(stackTrace: st);
      return false;
    }
  }

  /// Idempotent lobby presence ping — bumps RTDB lobby count once per uid/day.
  Future<int?> joinLobby({required String dateId}) async {
    try {
      final callable = _functions.httpsCallable('joinDailyWarLobby');
      final result = await callable.call<Map<String, dynamic>>({
        'dateId': dateId,
      });
      final data = result.data;
      if (data['ok'] != true) return null;
      return (data['lobbyCount'] as num?)?.toInt();
    } on Object catch (e, st) {
      debugPrint('DailyWarCloudService.joinLobby: $e');
      debugPrintStack(stackTrace: st);
      return null;
    }
  }
}

class DailyWarAdminPreview {
  const DailyWarAdminPreview({
    required this.dateId,
    required this.kind,
    required this.status,
    required this.topics,
    required this.nextTopics,
    required this.privateUuids,
    required this.publicUuids,
    required this.isPubliclyPublished,
    required this.questionCount,
  });

  final String dateId;
  final String kind;
  final String status;
  final List<Map<String, dynamic>> topics;
  final List<Map<String, dynamic>> nextTopics;
  final List<String> privateUuids;
  final List<String> publicUuids;
  final bool isPubliclyPublished;
  final int questionCount;

  factory DailyWarAdminPreview.fromMap(Map<String, dynamic> map) {
    List<String> asStrings(dynamic raw) {
      if (raw is! List) return const [];
      return raw.map((e) => '$e').toList();
    }

    List<Map<String, dynamic>> asMaps(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return DailyWarAdminPreview(
      dateId: '${map['dateId'] ?? ''}',
      kind: '${map['kind'] ?? 'daily'}',
      status: '${map['status'] ?? ''}',
      topics: asMaps(map['topics']),
      nextTopics: asMaps(map['next_topics']),
      privateUuids: asStrings(map['private_uuids']),
      publicUuids: asStrings(map['public_uuids']),
      isPubliclyPublished: map['is_publicly_published'] == true,
      questionCount: (map['question_count'] as num?)?.toInt() ?? 0,
    );
  }
}
