import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/anonymous_auth_service.dart';
import 'admin_dashboard_collection_config.dart';
import 'admin_dashboard_metrics.dart';
import 'admin_dashboard_period.dart';
import 'pending_notification_conversion.dart';

/// Firestore-backed product metrics for the in-app admin dashboard.
class AdminDashboardWriterService {
  AdminDashboardWriterService({
    FirebaseFirestore? firestore,
    bool? collectionEnabledOverride,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _collectionEnabledOverride = collectionEnabledOverride;

  final FirebaseFirestore _firestore;
  final bool? _collectionEnabledOverride;

  static const collectionName = 'admin_dashboard';

  bool get _collectionEnabled =>
      _collectionEnabledOverride ?? isAdminDashboardCollectionEnabled();

  DocumentReference<Map<String, dynamic>> _dailyRef(String dateKey) =>
      _firestore.collection(collectionName).doc('daily').collection('days').doc(dateKey);

  DocumentReference<Map<String, dynamic>> _lifecycleRef(String uid) =>
      _firestore.collection(collectionName).doc('user_lifecycle').collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _notificationRef(String id) =>
      _firestore.collection(collectionName).doc('notifications').collection('items').doc(id);

  Future<String?> _uid() async {
    await AnonymousAuthService.ensureSignedIn();
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> recordNewDownload() async {
    if (!_collectionEnabled) return;
    final uid = await _uid();
    if (uid == null) return;
    final today = adminDashboardTodayKey();
    try {
      await _firestore.runTransaction((tx) async {
        final life = await tx.get(_lifecycleRef(uid));
        if (life.exists && life.data()?['first_install_date'] != null) return;
        tx.set(
          _lifecycleRef(uid),
          {
            'first_install_date': today,
            'recorded_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        tx.set(
          _dailyRef(today),
          {AdminDashboardMetrics.newDownloads: FieldValue.increment(1)},
          SetOptions(merge: true),
        );
      });
    } catch (e, st) {
      _logError('recordNewDownload', e, st);
    }
  }

  Future<void> recordOnboardingCompleted() async {
    if (!_collectionEnabled) return;
    await _recordFirstTimeDaily(
      lifecycleField: 'onboarding_completed_date',
      dailyMetric: AdminDashboardMetrics.onboardingCompletedUsers,
    );
  }

  Future<void> recordFirstDemoTestCompleted() async {
    if (!_collectionEnabled) return;
    await _recordFirstTimeDaily(
      lifecycleField: 'first_demo_test_date',
      dailyMetric: AdminDashboardMetrics.firstDemoTestUsers,
    );
  }

  Future<void> _recordFirstTimeDaily({
    required String lifecycleField,
    required String dailyMetric,
  }) async {
    final uid = await _uid();
    if (uid == null) return;
    final today = adminDashboardTodayKey();
    try {
      await _firestore.runTransaction((tx) async {
        final life = await tx.get(_lifecycleRef(uid));
        if (life.exists && life.data()?[lifecycleField] != null) return;
        tx.set(
          _lifecycleRef(uid),
          {
            lifecycleField: today,
            'recorded_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        tx.set(
          _dailyRef(today),
          {dailyMetric: FieldValue.increment(1)},
          SetOptions(merge: true),
        );
      });
    } catch (e, st) {
      _logError('_recordFirstTimeDaily', e, st);
    }
  }

  Future<void> recordTestStarted({String? analyticsFeatureKey}) async {
    if (!_collectionEnabled) return;
    final uid = await _uid();
    if (uid == null) return;
    final today = adminDashboardTodayKey();
    try {
      await _recordUniqueDailyUser(
        dateKey: today,
        metric: AdminDashboardMetrics.testTakers,
        uid: uid,
      );
      await _firestore.runTransaction((tx) async {
        final life = await tx.get(_lifecycleRef(uid));
        if (life.exists && life.data()?['first_test_date'] != null) return;
        tx.set(
          _lifecycleRef(uid),
          {
            'first_test_date': today,
            'recorded_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        tx.set(
          _dailyRef(today),
          {AdminDashboardMetrics.firstTestUsers: FieldValue.increment(1)},
          SetOptions(merge: true),
        );
      });
      if (analyticsFeatureKey == 'mcq_battle') {
        await recordBattleEngagement();
      }
      await _maybeRecordNotificationConversion(isTestConversion: true);
    } catch (e, st) {
      _logError('recordTestStarted', e, st);
    }
  }

  Future<void> recordMemoryGamePlay({required bool isFirstEverOnDevice}) async {
    if (!_collectionEnabled) return;
    final uid = await _uid();
    if (uid == null) return;
    final today = adminDashboardTodayKey();
    try {
      await _incrementDailyCounter(today, AdminDashboardMetrics.memoryGamePlays);
      if (isFirstEverOnDevice) {
        await _firestore.runTransaction((tx) async {
          final life = await tx.get(_lifecycleRef(uid));
          if (life.exists && life.data()?['first_memory_game_date'] != null) {
            return;
          }
          tx.set(
            _lifecycleRef(uid),
            {
              'first_memory_game_date': today,
              'recorded_at': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
          tx.set(
            _dailyRef(today),
            {
              AdminDashboardMetrics.firstMemoryGameUsers: FieldValue.increment(1),
            },
            SetOptions(merge: true),
          );
        });
      }
      await _maybeRecordNotificationConversion(isMemoryGameConversion: true);
    } catch (e, st) {
      _logError('recordMemoryGamePlay', e, st);
    }
  }

  Future<void> recordBattleEngagement() async {
    if (!_collectionEnabled) return;
    final uid = await _uid();
    if (uid == null) return;
    final today = adminDashboardTodayKey();
    try {
      await _recordUniqueDailyUser(
        dateKey: today,
        metric: AdminDashboardMetrics.battleUsers,
        uid: uid,
      );
      await _firestore.runTransaction((tx) async {
        final life = await tx.get(_lifecycleRef(uid));
        if (life.exists && life.data()?['first_battle_date'] != null) return;
        tx.set(
          _lifecycleRef(uid),
          {
            'first_battle_date': today,
            'recorded_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
      await _maybeRecordNotificationConversion(isBattleConversion: true);
    } catch (e, st) {
      _logError('recordBattleEngagement', e, st);
    }
  }

  Future<void> recordChatEngagement() async {
    if (!_collectionEnabled) return;
    final uid = await _uid();
    if (uid == null) return;
    try {
      await _recordUniqueDailyUser(
        dateKey: adminDashboardTodayKey(),
        metric: AdminDashboardMetrics.chatUsers,
        uid: uid,
      );
    } catch (e, st) {
      _logError('recordChatEngagement', e, st);
    }
  }

  Future<void> recordNotificationOpen({
    required String notificationId,
    required String kind,
    String? title,
  }) async {
    if (!_collectionEnabled) return;
    final uid = await _uid();
    if (uid == null) return;
    final id = notificationId.trim();
    if (id.isEmpty) return;
    try {
      await _firestore.runTransaction((tx) async {
        final notif = _notificationRef(id);
        final openUser = notif.collection('open_users').doc(uid);
        final openSnap = await tx.get(openUser);
        if (openSnap.exists) return;
        tx.set(openUser, {'at': FieldValue.serverTimestamp()});
        tx.set(
          notif,
          {
            'kind': kind,
            if (title != null && title.isNotEmpty) 'title': title,
            'opens': FieldValue.increment(1),
            'updated_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
    } catch (e, st) {
      _logError('recordNotificationOpen', e, st);
    }
  }

  Future<void> _maybeRecordNotificationConversion({
    bool isTestConversion = false,
    bool isMemoryGameConversion = false,
    bool isBattleConversion = false,
  }) async {
    final pending = PendingNotificationConversion.take();
    if (pending == null) return;
    final kind = pending.kind ?? '';
    final converts = switch (kind) {
      'push_spot_test' || 'no_test_reminder' || 'daily_practice_reminder' =>
        isTestConversion,
      'memory_pairs' => isMemoryGameConversion,
      'battle_join' => isBattleConversion || isTestConversion,
      _ => isTestConversion || isMemoryGameConversion || isBattleConversion,
    };
    if (!converts) {
      PendingNotificationConversion.notificationId = pending.id;
      PendingNotificationConversion.kind = pending.kind;
      return;
    }
    await _recordNotificationConversion(pending.id);
  }

  Future<void> _recordNotificationConversion(String notificationId) async {
    final uid = await _uid();
    if (uid == null) return;
    final id = notificationId.trim();
    if (id.isEmpty) return;
    try {
      await _firestore.runTransaction((tx) async {
        final notif = _notificationRef(id);
        final convUser = notif.collection('conversion_users').doc(uid);
        final convSnap = await tx.get(convUser);
        if (convSnap.exists) return;
        tx.set(convUser, {'at': FieldValue.serverTimestamp()});
        tx.set(
          notif,
          {
            'conversions': FieldValue.increment(1),
            'updated_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
    } catch (e, st) {
      _logError('recordNotificationConversion', e, st);
    }
  }

  Future<void> _recordUniqueDailyUser({
    required String dateKey,
    required String metric,
    required String uid,
  }) async {
    await _firestore.runTransaction((tx) async {
      final userDoc = _dailyRef(dateKey)
          .collection('users')
          .doc('${metric}__$uid');
      final snap = await tx.get(userDoc);
      if (snap.exists) return;
      tx.set(userDoc, {'at': FieldValue.serverTimestamp()});
      tx.set(
        _dailyRef(dateKey),
        {metric: FieldValue.increment(1)},
        SetOptions(merge: true),
      );
    });
  }

  Future<void> _incrementDailyCounter(String dateKey, String metric) async {
    await _dailyRef(dateKey).set(
      {metric: FieldValue.increment(1)},
      SetOptions(merge: true),
    );
  }

  void _logError(String method, Object e, StackTrace st) {
    developer.log(
      'AdminDashboardWriterService.$method: $e',
      name: 'AdminDashboard',
      error: e,
      stackTrace: st,
    );
  }
}

/// Aggregated counters for one dashboard period.
class AdminDashboardPeriodSummary {
  const AdminDashboardPeriodSummary({
    required this.period,
    required this.newDownloads,
    required this.onboardingCompletedUsers,
    required this.firstDemoTestUsers,
    required this.firstTestUsers,
    required this.testTakers,
    required this.firstMemoryGameUsers,
    required this.memoryGamePlays,
    required this.battleUsers,
    required this.chatUsers,
  });

  final AdminDashboardPeriod period;
  final int newDownloads;
  final int onboardingCompletedUsers;
  final int firstDemoTestUsers;
  final int firstTestUsers;
  final int testTakers;
  final int firstMemoryGameUsers;
  final int memoryGamePlays;
  final int battleUsers;
  final int chatUsers;
}

class AdminDashboardNotificationStats {
  const AdminDashboardNotificationStats({
    required this.id,
    required this.kind,
    required this.title,
    required this.opens,
    required this.conversions,
    this.updatedAtMs = 0,
  });

  final String id;
  final String kind;
  final String title;
  final int opens;
  final int conversions;
  final int updatedAtMs;

  double get conversionRate => opens == 0 ? 0 : conversions / opens;
}

/// Reads Firestore aggregates for super-user dashboard screens.
class AdminDashboardReaderService {
  AdminDashboardReaderService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<AdminDashboardPeriodSummary> loadPeriodSummary(
    AdminDashboardPeriod period,
  ) async {
    final dates = adminDashboardDateKeysForPeriod(period);
    var newDownloads = 0;
    var onboardingCompletedUsers = 0;
    var firstDemoTestUsers = 0;
    var firstTestUsers = 0;
    var firstMemoryGameUsers = 0;
    var memoryGamePlays = 0;

    final uniqueSets = <String, Set<String>>{
      for (final m in [
        AdminDashboardMetrics.testTakers,
        AdminDashboardMetrics.battleUsers,
        AdminDashboardMetrics.chatUsers,
      ])
        m: {},
    };

    for (final dateKey in dates) {
      final dailySnap = await _firestore
          .collection(AdminDashboardWriterService.collectionName)
          .doc('daily')
          .collection('days')
          .doc(dateKey)
          .get();
      final data = dailySnap.data();
      if (data != null) {
        newDownloads += _asInt(data[AdminDashboardMetrics.newDownloads]);
        onboardingCompletedUsers +=
            _asInt(data[AdminDashboardMetrics.onboardingCompletedUsers]);
        firstDemoTestUsers +=
            _asInt(data[AdminDashboardMetrics.firstDemoTestUsers]);
        firstTestUsers += _asInt(data[AdminDashboardMetrics.firstTestUsers]);
        firstMemoryGameUsers +=
            _asInt(data[AdminDashboardMetrics.firstMemoryGameUsers]);
        memoryGamePlays += _asInt(data[AdminDashboardMetrics.memoryGamePlays]);
      }

      for (final metric in uniqueSets.keys) {
        final usersSnap = await _firestore
            .collection(AdminDashboardWriterService.collectionName)
            .doc('daily')
            .collection('days')
            .doc(dateKey)
            .collection('users')
            .where(FieldPath.documentId, isGreaterThanOrEqualTo: '${metric}__')
            .where(FieldPath.documentId, isLessThan: '${metric}__\uf8ff')
            .get();
        for (final doc in usersSnap.docs) {
          final uid = doc.id.substring('${metric}__'.length);
          uniqueSets[metric]!.add(uid);
        }
      }
    }

    return AdminDashboardPeriodSummary(
      period: period,
      newDownloads: newDownloads,
      onboardingCompletedUsers: onboardingCompletedUsers,
      firstDemoTestUsers: firstDemoTestUsers,
      firstTestUsers: firstTestUsers,
      testTakers: uniqueSets[AdminDashboardMetrics.testTakers]!.length,
      firstMemoryGameUsers: firstMemoryGameUsers,
      memoryGamePlays: memoryGamePlays,
      battleUsers: uniqueSets[AdminDashboardMetrics.battleUsers]!.length,
      chatUsers: uniqueSets[AdminDashboardMetrics.chatUsers]!.length,
    );
  }

  Future<List<AdminDashboardNotificationStats>> loadNotifications({
    int limit = 50,
  }) async {
    final snap = await _firestore
        .collection(AdminDashboardWriterService.collectionName)
        .doc('notifications')
        .collection('items')
        .limit(limit)
        .get();

    final items = snap.docs.map((doc) {
      final data = doc.data();
      return AdminDashboardNotificationStats(
        id: doc.id,
        kind: data['kind']?.toString() ?? '',
        title: data['title']?.toString() ?? '',
        opens: _asInt(data['opens']),
        conversions: _asInt(data['conversions']),
        updatedAtMs: _timestampMs(data['updated_at']),
      );
    }).toList();
    items.sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));
    return items;
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  int _timestampMs(Object? value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    return 0;
  }
}
