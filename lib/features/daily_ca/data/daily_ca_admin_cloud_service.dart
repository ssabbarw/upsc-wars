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
        options: HttpsCallableOptions(timeout: const Duration(minutes: 3)),
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
}

class DailyCaAdminException implements Exception {
  DailyCaAdminException(this.message);
  final String message;

  @override
  String toString() => message;
}
