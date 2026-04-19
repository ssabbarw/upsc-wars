import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Outcome of [BattleInviteCloudService.sendBattleInvite].
///
/// [notificationSent] is true only when the Cloud Function returned `{ ok: true }`
/// (FCM `send` succeeded). `no_token` / `send_failed` still mean the callable ran.
class BattleInviteOutcome {
  const BattleInviteOutcome._({
    required this.notificationSent,
    this.serverReason,
    this.transportError,
  });

  /// Push notification was handed to FCM successfully.
  final bool notificationSent;

  /// When [notificationSent] is false but [transportError] is null: `no_token` or `send_failed`.
  final String? serverReason;

  /// Callable/network error (e.g. unauthenticated, not deployed, offline).
  final Object? transportError;

  /// Callable finished without a transport/HTTPS error (response body may be `ok: false`).
  bool get callableCompleted => transportError == null;

  String get userFacingMessage {
    if (transportError != null) {
      if (transportError is FirebaseFunctionsException) {
        final e = transportError as FirebaseFunctionsException;
        return e.message ?? e.code;
      }
      return transportError.toString();
    }
    if (notificationSent) {
      return 'Battle invite sent.';
    }
    if (serverReason == 'no_token') {
      return 'Invitee has no push token yet. They can still join using the session link.';
    }
    if (serverReason == 'send_failed') {
      return 'Push could not be sent. They can still join using the session link.';
    }
    return 'Invite status unclear. Check Firebase Functions logs.';
  }

  /// Low-cardinality label for the `battle_invite_outcome` analytics event.
  String get analyticsKind {
    if (transportError != null) return 'transport_error';
    if (notificationSent) return 'push_ok';
    if (serverReason == 'no_token') return 'no_token';
    if (serverReason == 'send_failed') return 'send_failed';
    return 'server_unknown';
  }
}

/// Calls HTTPS callable `sendBattleInvite` (deploy separately; see docs).
class BattleInviteCloudService {
  const BattleInviteCloudService();

  /// Invokes the callable and inspects the returned map (`ok`, `reason`).
  Future<BattleInviteOutcome> sendBattleInvite({
    required String guestEmail,
    required String sessionId,
    required String hostDisplayName,
    required String subjectLabel,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'sendBattleInvite',
      );
      final result = await callable.call<Map<String, dynamic>>({
        'guestEmail': guestEmail.toLowerCase().trim(),
        'sessionId': sessionId,
        'hostDisplayName': hostDisplayName,
        'subjectLabel': subjectLabel,
      });
      final data = result.data;
      final ok = data['ok'] == true;
      if (ok) {
        debugPrint('BattleInviteCloudService: callable ok=true sessionId=$sessionId');
        return const BattleInviteOutcome._(notificationSent: true);
      }
      final reason = data['reason']?.toString();
      debugPrint(
        'BattleInviteCloudService: callable ok=false reason=$reason sessionId=$sessionId',
      );
      return BattleInviteOutcome._(
        notificationSent: false,
        serverReason: reason,
      );
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint(
        'BattleInviteCloudService.sendBattleInvite FirebaseFunctionsException: '
        '${e.code} ${e.message}',
      );
      debugPrintStack(stackTrace: st);
      return BattleInviteOutcome._(
        notificationSent: false,
        transportError: e,
      );
    } catch (e, st) {
      debugPrint('BattleInviteCloudService.sendBattleInvite: $e');
      debugPrintStack(stackTrace: st);
      return BattleInviteOutcome._(
        notificationSent: false,
        transportError: e,
      );
    }
  }
}
