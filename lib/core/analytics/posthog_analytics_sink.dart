import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import '../auth/auth_session.dart';
import 'analytics_audience.dart';
import 'analytics_event_mapper.dart';
import 'analytics_events.dart';
import 'analytics_sink.dart';
import 'posthog_bootstrap.dart';
import 'posthog_config.dart';

/// Fans [AnalyticsEvent]s to PostHog using the same names/params as GA4
/// ([mapAnalyticsEvent]). Disabled when [PostHogAppConfig] has no API key.
class PostHogAnalyticsSink implements AnalyticsSink {
  PostHogAnalyticsSink({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Opt in/out and identify with Firebase uid (same exclusion rules as GA4).
  static Future<void> syncForUser(User? user) async {
    if (!PostHogAppConfig.isConfigured || !PostHogBootstrap.isStarted) return;
    try {
      final excluded = AnalyticsAudience.isExcludedUser(user);
      if (excluded) {
        await Posthog().optOut();
        return;
      }
      await Posthog().optIn();
      final uid = user?.uid;
      if (uid == null || uid.isEmpty) return;
      // Anonymous Firebase users still get a stable distinct_id for retention.
      await Posthog().identify(
        userId: uid,
        userProperties: {
          'account_signed_in': AuthSession.isAccountSignedIn(user),
        },
      );
    } catch (e, st) {
      developer.log(
        'PostHog syncForUser failed: $e',
        name: 'PostHogAnalyticsSink',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> send(AnalyticsEvent event) async {
    if (!PostHogAppConfig.isConfigured || !PostHogBootstrap.isStarted) return;

    final mapping = mapAnalyticsEvent(event);
    final uid = _auth.currentUser?.uid;
    var attachedPersonProps = false;

    for (final mapped in mapping.events) {
      final properties = <String, Object>{
        ...mapped.params,
        if (uid case final u?) 'user_id': u,
      };
      // Attach person updates once per dispatch (PostHog `$set` person props).
      if (!attachedPersonProps && mapping.userProperties.isNotEmpty) {
        properties[r'$set'] = mapping.userProperties;
        attachedPersonProps = true;
      }
      await Posthog().capture(eventName: mapped.name, properties: properties);
    }
  }
}
