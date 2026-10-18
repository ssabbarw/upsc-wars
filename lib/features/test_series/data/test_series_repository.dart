import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/test_series_models.dart';

/// Loads a series (`test_series/{id}` + `tests` subcollection) from Firestore
/// and keeps the last good copy in SharedPreferences so the list opens offline
/// and instantly.
class TestSeriesRepository {
  TestSeriesRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static String _cacheKey(String seriesId) => 'test_series_bundle_v1_$seriesId';

  /// Last cached copy, or null.
  Future<SeriesBundle?> readCache(String seriesId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey(seriesId));
    if (raw == null || raw.isEmpty) return null;
    return SeriesBundle.fromJsonString(raw);
  }

  /// Fetches from Firestore and refreshes the cache. Throws on failure.
  Future<SeriesBundle> fetch(String seriesId) async {
    final seriesRef = _firestore.collection('test_series').doc(seriesId);
    final results = await Future.wait([
      seriesRef.get(),
      seriesRef.collection('tests').get(),
    ]);
    final seriesSnap = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final testsSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;
    if (!seriesSnap.exists) {
      throw StateError('Test series "$seriesId" does not exist.');
    }

    final info = TestSeriesInfo.fromMap(
      seriesId,
      _normalize(seriesSnap.data()!),
    );
    final tests = testsSnap.docs
        .map((d) => SeriesTest.fromMap(d.id, _normalize(d.data())))
        .toList();
    final bundle = SeriesBundle(info: info, tests: sortSeriesTests(tests));

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey(seriesId), bundle.toJsonString());
    } on Object catch (e) {
      developer.log('Failed to cache series $seriesId: $e', name: 'TestSeries');
    }
    return bundle;
  }

  /// Network first, falling back to the cache when offline.
  Future<SeriesBundle> load(String seriesId) async {
    try {
      return await fetch(seriesId);
    } on Object catch (e) {
      developer.log('Series fetch failed ($seriesId): $e', name: 'TestSeries');
      final cached = await readCache(seriesId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Converts Firestore `Timestamp` fields to the plain forms the models read.
  static Map<String, dynamic> _normalize(Map<String, dynamic> raw) {
    final out = Map<String, dynamic>.from(raw);
    final unlock = out['unlockAt'];
    if (unlock is Timestamp) {
      out['unlockAtMs'] = unlock.millisecondsSinceEpoch;
    }
    final launch = out['launchAt'];
    if (launch is Timestamp) {
      out['launchAtMs'] = launch.millisecondsSinceEpoch;
    }
    return out;
  }
}
