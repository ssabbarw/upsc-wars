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
    this.errorMessage,
  });

  final bool ok;
  final double? score;
  final int? correct;
  final int? wrong;
  final int? unanswered;
  final String? mode;
  final String? errorMessage;
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
      });
      final data = result.data;
      return DailyWarSubmitResult(
        ok: data['ok'] == true,
        score: (data['score'] as num?)?.toDouble(),
        correct: (data['correct'] as num?)?.toInt(),
        wrong: (data['wrong'] as num?)?.toInt(),
        unanswered: (data['unanswered'] as num?)?.toInt(),
        mode: data['mode']?.toString(),
      );
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('DailyWarCloudService.submit: ${e.code} ${e.message}');
      debugPrintStack(stackTrace: st);
      return DailyWarSubmitResult(
        ok: false,
        errorMessage: e.message ?? e.code,
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
}
