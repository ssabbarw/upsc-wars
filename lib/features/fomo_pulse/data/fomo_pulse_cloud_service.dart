import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../domain/fomo_pulse_models.dart';
import '../fomo_pulse_constants.dart';
import 'fomo_pulse_local_cache.dart';

enum FomoPulseSendTarget { self, broadcast }

class FomoPulseCloudService {
  FomoPulseCloudService({
    FirebaseFunctions? functions,
  }) : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFunctions _functions;

  Future<({String? draftDate, List<FomoPulseHarvestCandidate> candidates})>
      listHarvestCandidates() async {
    final callable = _functions.httpsCallable('listFomoPulseHarvestCandidates');
    final result = await callable.call<Map<String, dynamic>>({});
    final data = result.data;
    final raw = data['candidates'];
    final list = raw is List
        ? [
            for (final item in raw)
              if (item is Map)
                FomoPulseHarvestCandidate.fromMap(
                  Map<String, dynamic>.from(item),
                ),
          ]
        : <FomoPulseHarvestCandidate>[];
    return (
      draftDate: data['draft_date']?.toString(),
      candidates: list,
    );
  }

  Future<FomoPulseDraft> generateFromUrl(String url) async {
    final callable = _functions.httpsCallable('generateFomoPulseDraft');
    final result = await callable.call<Map<String, dynamic>>({
      'source': 'url',
      'url': url.trim(),
    });
    final draftRaw = result.data['draft'];
    if (draftRaw is! Map) {
      throw StateError('Invalid draft response');
    }
    return FomoPulseDraft.fromServerMap(Map<String, dynamic>.from(draftRaw));
  }

  Future<FomoPulseDraft> generateFromHarvest({
    required String draftDate,
    required String draftId,
  }) async {
    final callable = _functions.httpsCallable('generateFomoPulseDraft');
    final result = await callable.call<Map<String, dynamic>>({
      'source': 'harvest',
      'draft_date': draftDate,
      'draft_id': draftId,
    });
    final draftRaw = result.data['draft'];
    if (draftRaw is! Map) {
      throw StateError('Invalid draft response');
    }
    return FomoPulseDraft.fromServerMap(Map<String, dynamic>.from(draftRaw));
  }

  Future<({bool ok, String? pulseId, String? reason, String? target})>
      sendPulse({
    required String title,
    required String body,
    required String newsSummary,
    required String sourceUrl,
    required FomoPulseQuestion question,
    required FomoPulseSendTarget target,
    String? harvestDraftDate,
    String? harvestDraftId,
  }) async {
    final callable = _functions.httpsCallable('sendFomoPulseNotification');
    final result = await callable.call<Map<String, dynamic>>({
      'title': title.trim(),
      'body': body.trim(),
      'news_summary': newsSummary.trim(),
      'source_url': sourceUrl.trim(),
      'question': question.toServerMap(),
      'target': target == FomoPulseSendTarget.broadcast ? 'broadcast' : 'self',
      if (harvestDraftDate != null && harvestDraftId != null)
        'harvest': {
          'draft_date': harvestDraftDate,
          'draft_id': harvestDraftId,
        },
    });
    final data = result.data;
    return (
      ok: data['ok'] == true,
      pulseId: data['pulseId']?.toString(),
      reason: data['reason']?.toString(),
      target: data['target']?.toString(),
    );
  }

  Future<FomoPulseSubmitResult> submitAttempt({
    required String pulseId,
    required String selectedOption,
    required int timeSpentSecs,
  }) async {
    final callable = _functions.httpsCallable('submitFomoPulseAttempt');
    final result = await callable.call<Map<String, dynamic>>({
      'pulse_id': pulseId,
      'selected_option': selectedOption,
      'time_spent_secs': timeSpentSecs,
    });
    return FomoPulseSubmitResult.fromServerMap(result.data);
  }
}

class FomoPulseRepository {
  FomoPulseRepository({
    FirebaseFirestore? firestore,
    FomoPulseLocalCache? cache,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cache = cache ?? FomoPulseLocalCache();

  final FirebaseFirestore _firestore;
  final FomoPulseLocalCache _cache;

  static const _pulses = 'fomo_pulses';
  static const _userState = 'fomo_pulse_user_state';

  Future<FomoPulseHistoryData> loadHistory({bool forceRefresh = false}) async {
    final cached = await _cache.read();
    final fresh = await _cache.isListFresh();
    if (!forceRefresh && cached.pulses.isNotEmpty && fresh) {
      return (pulses: cached.pulses, attempts: cached.attempts);
    }
    try {
      final pulses = await fetchRecentPulses();
      final remoteAttempts = await fetchUserAttemptIndex();
      final attempts = {
        ...cached.attempts,
        ...remoteAttempts,
      };
      await _cache.writeList(pulses: pulses, attempts: attempts);
      return (pulses: pulses, attempts: attempts);
    } catch (_) {
      if (cached.pulses.isNotEmpty) {
        return (pulses: cached.pulses, attempts: cached.attempts);
      }
      rethrow;
    }
  }

  Future<({FomoPulse pulse, FomoPulseAttemptState? attempt})> loadPulse(
    String pulseId,
  ) async {
    final cached = await _cache.read();
    FomoPulse? cachedPulse;
    for (final p in cached.pulses) {
      if (p.pulseId == pulseId) {
        cachedPulse = p;
        break;
      }
    }
    if (cachedPulse != null) {
      return (pulse: cachedPulse, attempt: cached.attempts[pulseId]);
    }
    final pulse = await fetchPulse(pulseId);
    if (pulse == null) throw StateError('Pulse not found');
    await _cache.upsertPulse(pulse);
    return (pulse: pulse, attempt: cached.attempts[pulseId]);
  }

  Future<void> recordLocalAttempt({
    required String pulseId,
    required FomoPulseSubmitResult result,
  }) {
    return _cache.saveAttempt(
      pulseId: pulseId,
      attempt: FomoPulseAttemptState(
        attempted: true,
        isCorrect: result.isCorrect,
        selectedOption: result.selectedOption,
        timeSpentSecs: result.timeSpentSecs,
      ),
      attemptCount: result.attemptCount,
      correctCount: result.correctCount,
    );
  }

  Future<List<FomoPulse>> fetchRecentPulses({
    int limit = FomoPulseConstants.historyPageSize,
  }) async {
    final snap = await _firestore
        .collection(_pulses)
        .where('status', isEqualTo: 'sent')
        .orderBy('sent_at', descending: true)
        .limit(limit)
        .get();
    return [
      for (final doc in snap.docs)
        FomoPulse.fromFirestore(doc.id, doc.data()),
    ];
  }

  Future<FomoPulse?> fetchPulse(String pulseId) async {
    final doc = await _firestore.collection(_pulses).doc(pulseId).get();
    if (!doc.exists) return null;
    return FomoPulse.fromFirestore(doc.id, doc.data()!);
  }

  /// One read for all attempt statuses (cost-efficient history).
  Future<Map<String, FomoPulseAttemptState>> fetchUserAttemptIndex() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};
    final doc = await _firestore.collection(_userState).doc(uid).get();
    if (!doc.exists) return {};
    final data = doc.data();
    final attempts = data?['attempts'];
    if (attempts is! Map) return {};
    return {
      for (final entry in attempts.entries)
        entry.key.toString(): FomoPulseAttemptState.fromCompactMap(
          entry.value is Map
              ? Map<String, dynamic>.from(entry.value as Map)
              : null,
        ),
    };
  }
}

class FomoPulsePushOutcome {
  const FomoPulsePushOutcome._({
    required this.sent,
    this.pulseId,
    this.reason,
    this.target,
    this.error,
  });

  final bool sent;
  final String? pulseId;
  final String? reason;
  final String? target;
  final Object? error;

  String get userMessage {
    if (error != null) return error.toString();
    if (sent) {
      return target == 'broadcast'
          ? 'Pulse broadcast sent.'
          : 'Pulse sent to your device.';
    }
    return switch (reason) {
      'no_token' => 'No push token on your user doc.',
      'not_authorized' => 'Not allowed to broadcast.',
      'send_failed' => 'FCM delivery failed.',
      _ => 'Send failed.',
    };
  }
}

class FomoPulsePushService {
  FomoPulsePushService({FomoPulseCloudService? cloud})
      : cloud = cloud ?? FomoPulseCloudService();

  final FomoPulseCloudService cloud;

  Future<FomoPulsePushOutcome> send(
    FomoPulseDraft draft,
    FomoPulseSendTarget target,
  ) async {
    try {
      final outcome = await cloud.sendPulse(
        title: draft.notificationTitle,
        body: draft.notificationBody,
        newsSummary: draft.newsSummary,
        sourceUrl: draft.sourceUrl,
        question: draft.question,
        target: target,
        harvestDraftDate: draft.harvestDraftDate,
        harvestDraftId: draft.harvestDraftId,
      );
      return FomoPulsePushOutcome._(
        sent: outcome.ok,
        pulseId: outcome.pulseId,
        reason: outcome.reason,
        target: outcome.target,
      );
    } catch (e, st) {
      debugPrint('FomoPulsePushService.send: $e');
      debugPrintStack(stackTrace: st);
      return FomoPulsePushOutcome._(sent: false, error: e);
    }
  }
}
