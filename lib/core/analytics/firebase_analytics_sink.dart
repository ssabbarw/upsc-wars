import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'analytics_audience.dart';
import 'analytics_event_mapper.dart';
import 'analytics_events.dart';
import 'analytics_sink.dart';

/// Sends [AnalyticsEvent] instances to **Google Analytics 4 (Firebase)** via
/// [FirebaseAnalytics.logEvent]. The **English description** of each product
/// event lives on the corresponding class in [analytics_events.dart]. Wire
/// names and parameters are defined once in [mapAnalyticsEvent].
///
/// See [mapAnalyticsEvent] / the previous top-level comment history for the
/// GA4 event name quick reference.
///
/// All events also send `user_id` when the user is signed in to Firebase Auth.
class FirebaseAnalyticsSink implements AnalyticsSink {
  FirebaseAnalyticsSink({FirebaseAnalytics? analytics, FirebaseAuth? auth})
    : _analytics = analytics ?? FirebaseAnalytics.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAnalytics _analytics;
  final FirebaseAuth _auth;

  String? get _userId => _auth.currentUser?.uid;

  /// Turns GA4 collection off in debug and for admins/bots so automatic
  /// events (`first_open`, `session_start`, …) are not recorded either.
  static Future<void> syncCollectionForUser(User? user) {
    final enabled = !AnalyticsAudience.isExcludedUser(user);
    return FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
  }

  @override
  Future<void> send(AnalyticsEvent event) async {
    final mapping = mapAnalyticsEvent(event);
    for (final entry in mapping.userProperties.entries) {
      await _analytics.setUserProperty(name: entry.key, value: entry.value);
    }
    for (final mapped in mapping.events) {
      await _log(mapped.name, mapped.params);
    }
  }

  Future<void> _log(String name, Map<String, Object> params) async {
    final uid = _userId;
    final merged = <String, Object>{
      ...params,
      if (uid case final u?) 'user_id': u,
    };
    await _analytics.logEvent(name: name, parameters: merged);
  }
}
