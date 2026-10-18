import 'package:cloud_functions/cloud_functions.dart';

import 'test_series_access_service.dart';

/// Result of announcing a free offer.
class AnnounceOutcome {
  const AnnounceOutcome({
    required this.code,
    required this.notified,
    this.pushError,
  });

  final String code;

  /// False when the offer is live but the push did not go out (retry it).
  final bool notified;
  final String? pushError;
}

/// Admin callables for promo codes and free offers. Reads (the code list and
/// who redeemed) go straight to Firestore, which only super users may read.
class TestSeriesPromoAdminService {
  TestSeriesPromoAdminService({FirebaseFunctions? functions})
    : _functions =
          functions ??
          FirebaseFunctions.instanceFor(
            region: TestSeriesAccessService.functionsRegion,
          );

  final FirebaseFunctions _functions;

  Future<Map<Object?, Object?>> _call(
    String name,
    Map<String, dynamic> args,
  ) async {
    final result = await _functions
        .httpsCallable(name)
        .call<Map<Object?, Object?>>(args);
    return result.data;
  }

  /// Human-readable message for a failed call.
  static String describe(Object error) {
    if (error is FirebaseFunctionsException) {
      if (error.code == 'not-found' &&
          (error.message?.contains('NOT_FOUND') ?? false)) {
        return 'Function not deployed yet. Run firebase deploy --only functions.';
      }
      if (error.code == 'permission-denied') {
        return 'This account is not allowed to do that.';
      }
      return error.message ?? error.code;
    }
    return error.toString();
  }

  /// Creates a code. Leave [code] empty to generate one. Returns the code.
  Future<String> createCode({
    required String seriesId,
    required String label,
    String? code,
    int? maxRedemptions,
    DateTime? expiresAt,
  }) async {
    final data = await _call('adminCreateTestSeriesPromo', {
      'seriesId': seriesId,
      'label': label,
      if (code != null && code.trim().isNotEmpty) 'code': code.trim(),
      'maxRedemptions': ?maxRedemptions,
      if (expiresAt != null) 'expiresAt': expiresAt.toUtc().toIso8601String(),
    });
    return data['code'].toString();
  }

  Future<void> setCodeActive(String code, {required bool active}) async {
    await _call('adminSetTestSeriesPromoActive', {
      'code': code,
      'active': active,
    });
  }

  /// Opens a free-for-everyone offer and (optionally) pushes it to everyone.
  Future<AnnounceOutcome> announce({
    required String seriesId,
    String? title,
    String? body,
    bool notify = true,
    int? maxRedemptions,
    DateTime? expiresAt,
  }) async {
    final data = await _call('adminAnnounceFreeTestSeries', {
      'seriesId': seriesId,
      'notify': notify,
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      if (body != null && body.trim().isNotEmpty) 'body': body.trim(),
      'maxRedemptions': ?maxRedemptions,
      if (expiresAt != null) 'expiresAt': expiresAt.toUtc().toIso8601String(),
    });
    return AnnounceOutcome(
      code: data['code'].toString(),
      notified: data['notified'] == true,
      pushError: data['pushError']?.toString(),
    );
  }

  Future<void> resendPush(String seriesId) async {
    await _call('adminNotifyFreeTestSeriesOffer', {'seriesId': seriesId});
  }

  Future<void> closeOffer(String seriesId) async {
    await _call('adminCloseFreeTestSeriesOffer', {'seriesId': seriesId});
  }
}
