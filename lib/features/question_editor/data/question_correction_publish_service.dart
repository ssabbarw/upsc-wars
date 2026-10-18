import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Publishes a correction via Cloud Function `publishQuestionCorrection`.
class QuestionCorrectionPublishService {
  QuestionCorrectionPublishService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<QuestionCorrectionPublishOutcome> publish(
    Map<String, dynamic> correction,
  ) async {
    try {
      final callable = _functions.httpsCallable('publishQuestionCorrection');
      final result = await callable.call<Map<String, dynamic>>({
        'correction': correction,
      });
      final data = result.data;
      final revision = data['revision'];
      return QuestionCorrectionPublishOutcome(
        success: true,
        revision: revision is int
            ? revision
            : revision is num
            ? revision.toInt()
            : null,
      );
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('QuestionCorrectionPublishService: ${e.code} ${e.message}');
      debugPrintStack(stackTrace: st);
      return QuestionCorrectionPublishOutcome(
        success: false,
        message: e.message ?? e.code,
      );
    } catch (e, st) {
      debugPrint('QuestionCorrectionPublishService: $e');
      debugPrintStack(stackTrace: st);
      return QuestionCorrectionPublishOutcome(
        success: false,
        message: e.toString(),
      );
    }
  }
}

class QuestionCorrectionPublishOutcome {
  const QuestionCorrectionPublishOutcome({
    required this.success,
    this.revision,
    this.message,
  });

  final bool success;
  final int? revision;
  final String? message;
}
