import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../daily_ca_admin_constants.dart';

class DailyCaSubmitResult {
  const DailyCaSubmitResult({
    required this.ok,
    this.score,
    this.correct,
    this.wrong,
    this.unanswered,
    this.mode,
    this.air,
    this.percentile,
    this.participantCount,
    this.elapsedMs,
    this.errorMessage,
  });

  final bool ok;
  final double? score;
  final int? correct;
  final int? wrong;
  final int? unanswered;
  final String? mode;
  final int? air;
  final double? percentile;
  final int? participantCount;
  final int? elapsedMs;
  final String? errorMessage;
}

/// Callable client for Daily CA rank functions (`asia-south1`).
class DailyCaCloudService {
  const DailyCaCloudService();

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: DailyCaConstants.functionsRegion);

  Future<DailyCaSubmitResult> submit({
    required String dateId,
    required Map<String, String> answers,
    required int elapsedMs,
    String? displayName,
  }) async {
    try {
      final callable = _functions.httpsCallable('submitDailyCa');
      final result = await callable.call<Map<String, dynamic>>({
        'dateId': dateId,
        'answers': answers,
        'elapsedMs': elapsedMs,
        if (displayName != null && displayName.isNotEmpty)
          'displayName': displayName,
      });
      final data = result.data;
      return DailyCaSubmitResult(
        ok: data['ok'] == true,
        score: (data['score'] as num?)?.toDouble(),
        correct: (data['correct'] as num?)?.toInt(),
        wrong: (data['wrong'] as num?)?.toInt(),
        unanswered: (data['unanswered'] as num?)?.toInt(),
        mode: data['mode']?.toString(),
        air: (data['air'] as num?)?.toInt(),
        percentile: (data['percentile'] as num?)?.toDouble(),
        participantCount: (data['participant_count'] as num?)?.toInt(),
        elapsedMs: (data['elapsed_ms'] as num?)?.toInt(),
      );
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('DailyCaCloudService.submit: ${e.code} ${e.message}');
      debugPrintStack(stackTrace: st);
      return DailyCaSubmitResult(
        ok: false,
        errorMessage: e.message ?? e.code,
      );
    } on Object catch (e, st) {
      debugPrint('DailyCaCloudService.submit: $e');
      debugPrintStack(stackTrace: st);
      return DailyCaSubmitResult(ok: false, errorMessage: e.toString());
    }
  }

  /// Current AIR — computed on the server from everyone who has finished.
  Future<DailyCaSubmitResult> myRank({required String dateId}) async {
    try {
      final callable = _functions.httpsCallable('getDailyCaMyRank');
      final result = await callable.call<Map<String, dynamic>>({
        'dateId': dateId,
      });
      final data = result.data;
      return DailyCaSubmitResult(
        ok: data['ok'] == true,
        score: (data['score'] as num?)?.toDouble(),
        correct: (data['correct'] as num?)?.toInt(),
        wrong: (data['wrong'] as num?)?.toInt(),
        unanswered: (data['unanswered'] as num?)?.toInt(),
        mode: data['mode']?.toString(),
        air: (data['air'] as num?)?.toInt(),
        percentile: (data['percentile'] as num?)?.toDouble(),
        participantCount: (data['participant_count'] as num?)?.toInt(),
        elapsedMs: (data['elapsed_ms'] as num?)?.toInt(),
      );
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('DailyCaCloudService.myRank: ${e.code} ${e.message}');
      debugPrintStack(stackTrace: st);
      return DailyCaSubmitResult(
        ok: false,
        errorMessage: e.message ?? e.code,
      );
    } on Object catch (e, st) {
      debugPrint('DailyCaCloudService.myRank: $e');
      debugPrintStack(stackTrace: st);
      return DailyCaSubmitResult(ok: false, errorMessage: e.toString());
    }
  }
}
