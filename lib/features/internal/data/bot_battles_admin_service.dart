import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/admin_dashboard/admin_dashboard_period.dart';
import '../../../core/admin_dashboard/admin_dashboard_service.dart';

/// One human-vs-traffic-bot MCQ battle, written by Cloud Functions.
class BotBattleSession {
  const BotBattleSession({
    required this.sessionId,
    required this.humanEmail,
    required this.botEmail,
    required this.botId,
    required this.direction,
    required this.subject,
    required this.humanDisplayName,
    required this.botName,
    required this.dateId,
    required this.status,
    required this.joinedAtMs,
    this.botFinishedAtMs = 0,
    this.humanSubmittedAtMs = 0,
    this.completedAtMs = 0,
  });

  final String sessionId;
  final String humanEmail;
  final String botEmail;
  final String botId;
  final String direction;
  final String subject;
  final String humanDisplayName;
  final String botName;
  final String dateId;
  final String status;
  final int joinedAtMs;
  final int botFinishedAtMs;
  final int humanSubmittedAtMs;
  final int completedAtMs;

  bool get isCompleted => status == 'completed' || completedAtMs > 0;

  bool get isOutgoing => direction == 'outgoing';

  factory BotBattleSession.fromDoc(String id, Map<String, dynamic>? map) {
    if (map == null) {
      return BotBattleSession(
        sessionId: id,
        humanEmail: '',
        botEmail: '',
        botId: '',
        direction: 'incoming',
        subject: '',
        humanDisplayName: '',
        botName: '',
        dateId: '',
        status: 'joined',
        joinedAtMs: 0,
      );
    }
    return BotBattleSession(
      sessionId: (map['sessionId'] as String?)?.trim().isNotEmpty == true
          ? (map['sessionId'] as String).trim()
          : id,
      humanEmail: _str(map['humanEmail']),
      botEmail: _str(map['botEmail']),
      botId: _str(map['botId']),
      direction: _str(map['direction']) == 'outgoing' ? 'outgoing' : 'incoming',
      subject: _str(map['subject']),
      humanDisplayName: _str(map['humanDisplayName']),
      botName: _str(map['botName']),
      dateId: _str(map['dateId']),
      status: _str(map['status']) == 'completed' ? 'completed' : 'joined',
      joinedAtMs: _asInt(map['joinedAtMs']),
      botFinishedAtMs: _asInt(map['botFinishedAtMs']),
      humanSubmittedAtMs: _asInt(map['humanSubmittedAtMs']),
      completedAtMs: _asInt(map['completedAtMs']),
    );
  }
}

class BotBattlesAdminSnapshot {
  const BotBattlesAdminSnapshot({
    required this.period,
    required this.uniqueJoins,
    required this.uniqueCompletions,
    required this.joinSessions,
    required this.completionSessions,
    required this.peopleLast24h,
    required this.completedPeopleLast24h,
    required this.recent,
  });

  final AdminDashboardPeriod period;
  final int uniqueJoins;
  final int uniqueCompletions;
  final int joinSessions;
  final int completionSessions;
  final int peopleLast24h;
  final int completedPeopleLast24h;
  final List<BotBattleSession> recent;

  double get completionRate =>
      uniqueJoins == 0 ? 0 : uniqueCompletions / uniqueJoins;
}

/// Super-user reads of `admin_dashboard/bot_battles` and 24h counters on traffic_bots.
class BotBattlesAdminService {
  BotBattlesAdminService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const collectionName = AdminDashboardWriterService.collectionName;
  static const rootDoc = 'bot_battles';

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection(collectionName).doc(rootDoc).collection('sessions');

  CollectionReference<Map<String, dynamic>> get _daily =>
      _firestore.collection(collectionName).doc(rootDoc).collection('daily');

  Future<BotBattlesAdminSnapshot> load({
    required AdminDashboardPeriod period,
    DateTime? nowUtc,
  }) async {
    final dates = adminDashboardIstDateKeysForPeriod(period, nowUtc: nowUtc);
    var joinSessions = 0;
    var completionSessions = 0;
    final joinEmails = <String>{};
    final completionEmails = <String>{};

    for (final dateId in dates) {
      final daySnap = await _daily.doc(dateId).get();
      final data = daySnap.data();
      if (data != null) {
        joinSessions += _asInt(data['joins']);
        completionSessions += _asInt(data['completions']);
      }
      final joinsSnap = await _daily.doc(dateId).collection('join_users').get();
      for (final doc in joinsSnap.docs) {
        if (doc.id.trim().isNotEmpty)
          joinEmails.add(doc.id.trim().toLowerCase());
      }
      final completionsSnap = await _daily
          .doc(dateId)
          .collection('completion_users')
          .get();
      for (final doc in completionsSnap.docs) {
        if (doc.id.trim().isNotEmpty) {
          completionEmails.add(doc.id.trim().toLowerCase());
        }
      }
    }

    final recentSnap = await _sessions
        .orderBy('joinedAtMs', descending: true)
        .limit(40)
        .get();
    final recent = recentSnap.docs
        .map((doc) => BotBattleSession.fromDoc(doc.id, doc.data()))
        .toList();

    final trafficSnap = await _firestore
        .collection(collectionName)
        .doc('traffic_bots')
        .get();
    final traffic = trafficSnap.data() ?? const <String, dynamic>{};

    return BotBattlesAdminSnapshot(
      period: period,
      uniqueJoins: joinEmails.length,
      uniqueCompletions: completionEmails.length,
      joinSessions: joinSessions,
      completionSessions: completionSessions,
      peopleLast24h: _asInt(traffic['warPeopleLast24h']),
      completedPeopleLast24h: _asInt(traffic['battleCompletedPeopleLast24h']),
      recent: recent,
    );
  }
}

String _str(Object? value) => value == null ? '' : '$value'.trim();

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}
