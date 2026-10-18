import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../daily_ca_admin_constants.dart';

class DailyCaAdminCloudService {
  DailyCaAdminCloudService({FirebaseFunctions? functions})
    : _functions =
          functions ??
          FirebaseFunctions.instanceFor(
            region: DailyCaAdminConstants.functionsRegion,
          );

  final FirebaseFunctions _functions;

  Future<void> saveDraft({
    required String date,
    required List<Map<String, dynamic>> questions,
    required List<String> chosenIds,
  }) async {
    final callable = _functions.httpsCallable('updateDailyCaDraft');
    await callable.call<Map<String, dynamic>>({
      'date': date,
      'questions': questions,
      'chosen_uuids': chosenIds,
    });
  }

  Future<int> publish({
    required String date,
    required List<String> chosenIds,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'publishDailyCaDay',
        options: HttpsCallableOptions(timeout: const Duration(minutes: 9)),
      );
      final result = await callable.call<Map<String, dynamic>>({
        'date': date,
        'chosen_uuids': chosenIds,
      });
      final count = result.data['count'];
      if (count is int) return count;
      if (count is num) return count.toInt();
      return chosenIds.length;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('publishDailyCaDay: ${e.code} ${e.message}');
      debugPrintStack(stackTrace: st);
      throw DailyCaAdminException(e.message ?? e.code);
    }
  }

  Future<int> autoPublish({required String date}) async {
    try {
      final callable = _functions.httpsCallable(
        'adminAutoPublishDailyCa',
        options: HttpsCallableOptions(timeout: const Duration(minutes: 9)),
      );
      final result = await callable.call<Map<String, dynamic>>({'date': date});
      final count = result.data['count'];
      if (count is int) return count;
      if (count is num) return count.toInt();
      return 0;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('adminAutoPublishDailyCa: ${e.code} ${e.message}');
      debugPrintStack(stackTrace: st);
      throw DailyCaAdminException(e.message ?? e.code);
    }
  }

  Future<DailyCaGenerateResult> generate({
    required String date,
    bool force = false,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'adminGenerateDailyCa',
        options: HttpsCallableOptions(
          timeout: DailyCaAdminConstants.generateTimeout,
        ),
      );
      final result = await callable.call<Object?>({
        'date': date,
        'force': force,
      });
      final raw = result.data;
      final map = raw is Map
          ? Map<String, dynamic>.from(raw)
          : <String, dynamic>{};
      return DailyCaGenerateResult.fromMap(map);
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('adminGenerateDailyCa: ${e.code} ${e.message}');
      debugPrintStack(stackTrace: st);
      throw DailyCaAdminException(e.message ?? e.code);
    }
  }
}

class DailyCaGenerateResult {
  const DailyCaGenerateResult({
    required this.ok,
    required this.skipped,
    required this.date,
    required this.questionCount,
    this.error,
    this.reason,
  });

  final bool ok;
  final bool skipped;
  final String date;
  final int questionCount;
  final String? error;
  final String? reason;

  factory DailyCaGenerateResult.fromMap(Map<String, dynamic> data) {
    final count = data['question_count'];
    final error = data['error']?.toString().trim();
    final reason = data['reason']?.toString().trim();
    return DailyCaGenerateResult(
      ok: data['ok'] == true,
      skipped: data['skipped'] == true,
      date: '${data['date'] ?? ''}',
      questionCount: count is int
          ? count
          : count is num
          ? count.toInt()
          : 0,
      error: (error == null || error.isEmpty) ? null : error,
      reason: (reason == null || reason.isEmpty) ? null : reason,
    );
  }

  bool get wroteDraft => ok && !skipped && questionCount > 0;

  String get userMessage {
    switch (reason) {
      case 'already_exists':
        return 'A draft already exists for $date. Open Daily CA review to overwrite.';
      case 'in_progress':
        return error ??
            'Generation is already running. Wait for the review notification.';
      case 'sunday':
        return 'Sunday has no current-affairs paper.';
      default:
        break;
    }
    if (wroteDraft) {
      return 'Draft ready — $questionCount questions. Open Daily CA review.';
    }
    if (error != null) return error!;
    if (ok) return 'Generation finished.';
    return 'Generation failed.';
  }
}

class DailyCaAdminException implements Exception {
  DailyCaAdminException(this.message);
  final String message;

  @override
  String toString() => message;
}
