import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/analytics/analytics_audience.dart';
import 'package:upsc_wars/core/constants/super_user_emails.dart';

void main() {
  group('AnalyticsAudience', () {
    test('excludes debug builds even for regular users', () {
      expect(
        AnalyticsAudience.isExcluded(
          email: 'student@gmail.com',
          accountSignedIn: true,
          debugMode: true,
        ),
        isTrue,
      );
    });

    test('excludes listed admin emails when signed in', () {
      expect(
        AnalyticsAudience.isExcluded(
          email: SuperUserEmails.emails.first,
          accountSignedIn: true,
          debugMode: false,
        ),
        isTrue,
      );
      expect(
        AnalyticsAudience.isExcluded(
          email: SuperUserEmails.emails.first.toUpperCase(),
          accountSignedIn: true,
          debugMode: false,
        ),
        isTrue,
      );
    });

    test('does not exclude admin email before account sign-in', () {
      expect(
        AnalyticsAudience.isExcluded(
          email: SuperUserEmails.emails.first,
          accountSignedIn: false,
          debugMode: false,
        ),
        isFalse,
      );
    });

    test('does not exclude regular signed-in users in release', () {
      expect(
        AnalyticsAudience.isExcluded(
          email: 'student@gmail.com',
          accountSignedIn: true,
          debugMode: false,
        ),
        isFalse,
      );
    });

    test('excludes reserved bot mailbox domains', () {
      expect(
        AnalyticsAudience.isReservedBotEmail('priya@community.upscwars.in'),
        isTrue,
      );
      expect(
        AnalyticsAudience.isReservedBotEmail('legacy@upscwars.bot'),
        isTrue,
      );
      expect(
        AnalyticsAudience.isExcluded(
          email: 'aarav.kumar11@community.upscwars.in',
          accountSignedIn: false,
          debugMode: false,
        ),
        isTrue,
      );
    });

    test('excludes explicit isBot flag', () {
      expect(
        AnalyticsAudience.isExcluded(
          email: 'someone@gmail.com',
          accountSignedIn: true,
          isBot: true,
          debugMode: false,
        ),
        isTrue,
      );
    });
  });
}
