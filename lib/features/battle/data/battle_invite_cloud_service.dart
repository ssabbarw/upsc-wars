import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Calls a HTTPS callable `sendBattleInvite` (deploy separately; see docs).
class BattleInviteCloudService {
  const BattleInviteCloudService();

  Future<void> sendBattleInvite({
    required String guestEmail,
    required String sessionId,
    required String hostDisplayName,
    required String subjectLabel,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('sendBattleInvite');
      await callable.call<Map<String, dynamic>>({
        'guestEmail': guestEmail.toLowerCase().trim(),
        'sessionId': sessionId,
        'hostDisplayName': hostDisplayName,
        'subjectLabel': subjectLabel,
      });
    } catch (e, st) {
      debugPrint('BattleInviteCloudService.sendBattleInvite: $e');
      debugPrintStack(stackTrace: st);
    }
  }
}
