import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// The public "free for you, claim it" offer (`test_series_open_offer/{id}`).
class SeriesOpenOffer {
  const SeriesOpenOffer({
    required this.seriesId,
    required this.code,
    this.expiresAt,
  });

  final String seriesId;

  /// Hidden code the app redeems on the user's behalf.
  final String code;
  final DateTime? expiresAt;

  bool get isLive => expiresAt == null || expiresAt!.isAfter(DateTime.now());
}

enum RedeemKind { redeemed, alreadyOwned, rejected, failed }

class RedeemOutcome {
  const RedeemOutcome(this.kind, {this.seriesId, this.message});

  final RedeemKind kind;
  final String? seriesId;

  /// User-facing reason for [RedeemKind.rejected] / [RedeemKind.failed].
  final String? message;

  bool get granted =>
      kind == RedeemKind.redeemed || kind == RedeemKind.alreadyOwned;
}

/// Free access to a series, granted by Cloud Functions and stored per account:
/// `test_series_grants/{uid}`. The uid belongs to the Google/Apple account, so
/// a grant follows the user across reinstalls and devices.
class TestSeriesAccessService {
  TestSeriesAccessService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _firestore = firestore,
      _functions = functions;

  static const _logName = 'TestSeriesAccess';
  static const functionsRegion = 'asia-south1';

  final FirebaseFirestore? _firestore;
  final FirebaseFunctions? _functions;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  FirebaseFunctions get _fns =>
      _functions ?? FirebaseFunctions.instanceFor(region: functionsRegion);

  /// Series ids granted to [uid]. Throws when the read fails, so callers can
  /// tell "no grants" from "could not check".
  Future<Set<String>> fetchGrantedSeriesIds(String uid) async {
    final snap = await _db.collection('test_series_grants').doc(uid).get();
    final series = snap.data()?['series'];
    if (series is! Map) return const {};
    return series.keys.map((k) => k.toString()).toSet();
  }

  /// The live open offer for [seriesId], or null.
  Future<SeriesOpenOffer?> fetchOpenOffer(String seriesId) async {
    final snap = await _db.collection('test_series_open_offer').doc(seriesId).get();
    final d = snap.data();
    if (d == null || d['active'] != true) return null;
    final code = d['promoCode'];
    if (code is! String || code.isEmpty) return null;
    final exp = d['expiresAt'];
    final offer = SeriesOpenOffer(
      seriesId: seriesId,
      code: code,
      expiresAt: exp is Timestamp ? exp.toDate() : null,
    );
    return offer.isLive ? offer : null;
  }

  Future<RedeemOutcome> redeem(String code) async {
    try {
      final result = await _fns
          .httpsCallable('redeemTestSeriesCode')
          .call<Map<Object?, Object?>>({'code': code});
      final data = result.data;
      final seriesId = data['seriesId']?.toString();
      return RedeemOutcome(
        data['status'] == 'already_owned'
            ? RedeemKind.alreadyOwned
            : RedeemKind.redeemed,
        seriesId: seriesId,
      );
    } on FirebaseFunctionsException catch (e) {
      developer.log('redeem failed: ${e.code} ${e.message}', name: _logName);
      switch (e.code) {
        case 'not-found':
        case 'failed-precondition':
        case 'resource-exhausted':
        case 'unauthenticated':
          return RedeemOutcome(RedeemKind.rejected, message: e.message);
        default:
          return const RedeemOutcome(
            RedeemKind.failed,
            message: 'Could not check the code. Check your connection and try again.',
          );
      }
    } on Object catch (e) {
      developer.log('redeem failed: $e', name: _logName);
      return const RedeemOutcome(
        RedeemKind.failed,
        message: 'Could not check the code. Check your connection and try again.',
      );
    }
  }
}
