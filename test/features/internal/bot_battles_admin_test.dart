import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/admin_dashboard/admin_dashboard_period.dart';
import 'package:upsc_wars/features/internal/data/bot_battles_admin_service.dart';

void main() {
  group('adminDashboardIstDateKeysForPeriod', () {
    test('uses IST calendar date, not UTC', () {
      // 2026-08-19 20:00 UTC = 2026-08-20 01:30 IST
      final keys = adminDashboardIstDateKeysForPeriod(
        AdminDashboardPeriod.day,
        nowUtc: DateTime.utc(2026, 8, 19, 20),
      );
      expect(keys, ['2026-08-20']);
    });

    test('returns inclusive 7-day IST window', () {
      final keys = adminDashboardIstDateKeysForPeriod(
        AdminDashboardPeriod.week,
        nowUtc: DateTime.utc(2026, 8, 20, 10),
      );
      expect(keys.first, '2026-08-14');
      expect(keys.last, '2026-08-20');
      expect(keys, hasLength(7));
    });
  });

  group('BotBattleSession', () {
    test('parses completed session', () {
      final session = BotBattleSession.fromDoc('abc', {
        'sessionId': 'abc',
        'humanEmail': 'A@B.com',
        'botEmail': 'priya.k42@community.upscwars.in',
        'botId': 'bot_priya_k42',
        'direction': 'outgoing',
        'subject': 'Polity',
        'humanDisplayName': 'Aarav',
        'botName': 'Priya K',
        'dateId': '2026-08-20',
        'status': 'completed',
        'joinedAtMs': 10,
        'botFinishedAtMs': 20,
        'humanSubmittedAtMs': 30,
        'completedAtMs': 30,
      });
      expect(session.isCompleted, isTrue);
      expect(session.isOutgoing, isTrue);
      expect(session.humanEmail, 'A@B.com');
      expect(session.subject, 'Polity');
    });

    test('defaults missing maps to joined incoming', () {
      final session = BotBattleSession.fromDoc('x', null);
      expect(session.sessionId, 'x');
      expect(session.isCompleted, isFalse);
      expect(session.isOutgoing, isFalse);
    });
  });

  group('BotBattlesAdminSnapshot', () {
    test('completion rate is unique finished / unique joined', () {
      const snap = BotBattlesAdminSnapshot(
        period: AdminDashboardPeriod.day,
        uniqueJoins: 4,
        uniqueCompletions: 1,
        joinSessions: 5,
        completionSessions: 1,
        peopleLast24h: 2,
        completedPeopleLast24h: 1,
        recent: [],
      );
      expect(snap.completionRate, 0.25);
    });

    test('completion rate is 0 when nobody joined', () {
      const snap = BotBattlesAdminSnapshot(
        period: AdminDashboardPeriod.day,
        uniqueJoins: 0,
        uniqueCompletions: 0,
        joinSessions: 0,
        completionSessions: 0,
        peopleLast24h: 0,
        completedPeopleLast24h: 0,
        recent: [],
      );
      expect(snap.completionRate, 0);
    });
  });
}
