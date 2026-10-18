import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/core/providers/catalog_providers.dart';
import 'package:upsc_wars/core/providers/prefs_provider.dart';
import 'package:upsc_wars/features/battle/data/battle_firestore_paths.dart';
import 'package:upsc_wars/features/battle/data/battle_room_repository.dart';
import 'package:upsc_wars/features/battle/domain/battle_scoring.dart';

/// Live battle board after you submit while the opponent may still be playing.
class BattleSpectateState {
  const BattleSpectateState({
    required this.sessionId,
    required this.playerId,
    required this.opponentId,
    required this.playerName,
    required this.opponentName,
    required this.playerPhotoUrl,
    required this.questions,
    required this.playerByUuid,
    required this.opponentByUuid,
    required this.deadline,
    this.opponentPaperSubmitted = false,
  });

  final String sessionId;
  final String playerId;
  final String opponentId;
  final String playerName;
  final String opponentName;
  final String? playerPhotoUrl;
  final List<TestQuestion> questions;
  final Map<String, String> playerByUuid;
  final Map<String, String> opponentByUuid;
  final DateTime deadline;

  /// From opponent's `joined_users.battle_paper_submitted` (they submitted the test).
  final bool opponentPaperSubmitted;

  bool get opponentCaughtUp =>
      questions.every((q) => opponentByUuid.containsKey(q.uuid));

  bool get timerExpired => DateTime.now().isAfter(deadline);

  /// Opponent finished all questions, submitted the paper, or timer window ended.
  bool get battleSettled =>
      opponentCaughtUp || opponentPaperSubmitted || timerExpired;

  bool get opponentStillPlaying => !opponentCaughtUp && !timerExpired;

  List<bool?> get playerOutcomes => _outcomes(playerByUuid);

  List<bool?> get opponentOutcomes => _outcomes(opponentByUuid);

  double get playerPoints => calculateUpscBattleScore(
    questions: questions,
    selectedOptionByQuestion: playerByUuid,
  ).points;

  double get opponentPoints => calculateUpscBattleScore(
    questions: questions,
    selectedOptionByQuestion: opponentByUuid,
  ).points;

  List<bool?> _outcomes(Map<String, String> byUuid) {
    return questions.map((q) {
      final sel = byUuid[q.uuid];
      if (sel == null) return null;
      return sel.toLowerCase() == q.correctOption.toLowerCase();
    }).toList();
  }

  BattleSpectateState copyWith({
    Map<String, String>? playerByUuid,
    Map<String, String>? opponentByUuid,
    bool? opponentPaperSubmitted,
  }) {
    return BattleSpectateState(
      sessionId: sessionId,
      playerId: playerId,
      opponentId: opponentId,
      playerName: playerName,
      opponentName: opponentName,
      playerPhotoUrl: playerPhotoUrl,
      questions: questions,
      playerByUuid: playerByUuid ?? this.playerByUuid,
      opponentByUuid: opponentByUuid ?? this.opponentByUuid,
      deadline: deadline,
      opponentPaperSubmitted:
          opponentPaperSubmitted ?? this.opponentPaperSubmitted,
    );
  }
}

class BattleSpectateStartArgs {
  const BattleSpectateStartArgs({
    required this.sessionId,
    required this.playerId,
    required this.opponentId,
    required this.playerName,
    required this.opponentName,
    required this.playerPhotoUrl,
    required this.questions,
    required this.playerByUuid,
    required this.opponentByUuid,
    required this.deadline,
    this.opponentPaperSubmitted = false,
  });

  final String sessionId;
  final String playerId;
  final String opponentId;
  final String playerName;
  final String opponentName;
  final String? playerPhotoUrl;
  final List<TestQuestion> questions;
  final Map<String, String> playerByUuid;
  final Map<String, String> opponentByUuid;
  final DateTime deadline;
  final bool opponentPaperSubmitted;
}

class BattleSpectateNotifier extends StateNotifier<BattleSpectateState?> {
  BattleSpectateNotifier(this.ref) : super(null);

  final Ref ref;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  CollectionReference<Map<String, dynamic>> _joinedUsersCol(String roomId) {
    return BattleFirestorePaths.joinedUsersCol(roomId);
  }

  /// Loads last spectate session from prefs (same device) and re-subscribes.
  void scheduleRestoreFromPrefs() {
    Future(() async {
      if (state != null) return;
      final prefs = await ref.read(prefsServiceProvider.future);
      final raw = prefs.battleSpectateRecoveryJson;
      if (raw == null || raw.isEmpty) return;

      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        final sessionId = m['sessionId'] as String?;
        if (sessionId == null || sessionId.isEmpty) return;

        final load = await ref.read(loadSessionUseCaseProvider.future);
        final base = await load.execute(sessionId);

        if (state != null) return;

        final deadline =
            DateTime.tryParse(m['deadline'] as String? ?? '') ??
            DateTime.now().add(const Duration(days: 1));

        start(
          BattleSpectateStartArgs(
            sessionId: sessionId,
            playerId: (m['playerId'] as String?) ?? '',
            opponentId: (m['opponentId'] as String?) ?? '',
            playerName: (m['playerName'] as String?) ?? 'You',
            opponentName: (m['opponentName'] as String?) ?? 'Opponent',
            playerPhotoUrl: m['playerPhotoUrl'] as String?,
            questions: base.questions,
            playerByUuid: _decodeStringMap(m['playerByUuid']),
            opponentByUuid: _decodeStringMap(m['opponentByUuid']),
            deadline: deadline,
            opponentPaperSubmitted:
                (m['opponentPaperSubmitted'] as bool?) ?? false,
          ),
        );
      } catch (e, st) {
        debugPrint('BattleSpectateNotifier.restore failed: $e');
        debugPrintStack(stackTrace: st);
        await _clearPrefs();
      }
    });
  }

  static Map<String, String> _decodeStringMap(Object? raw) {
    if (raw is! Map) return {};
    return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  void start(BattleSpectateStartArgs args) {
    _sub?.cancel();
    state = BattleSpectateState(
      sessionId: args.sessionId,
      playerId: args.playerId,
      opponentId: args.opponentId,
      playerName: args.playerName,
      opponentName: args.opponentName,
      playerPhotoUrl: args.playerPhotoUrl,
      questions: args.questions,
      playerByUuid: Map<String, String>.from(args.playerByUuid),
      opponentByUuid: Map<String, String>.from(args.opponentByUuid),
      deadline: args.deadline,
      opponentPaperSubmitted: args.opponentPaperSubmitted,
    );
    _sub = _joinedUsersCol(
      args.sessionId,
    ).snapshots().listen(_onSnapshot, onError: (_) {});
    unawaited(_persistSnapshot());
  }

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    final cur = state;
    if (cur == null) return;
    Map<String, String>? playerDoc;
    Map<String, String>? oppDoc;
    var opponentPaper = cur.opponentPaperSubmitted;
    for (final d in snap.docs) {
      if (d.id == cur.playerId) {
        playerDoc = _responsesFromList(d.data()['responses'], cur.questions);
      }
      if (d.id == cur.opponentId) {
        oppDoc = _responsesFromList(d.data()['responses'], cur.questions);
        final data = d.data();
        if ((data['battle_paper_submitted'] as bool?) == true) {
          opponentPaper = true;
        }
      }
    }
    state = cur.copyWith(
      playerByUuid: playerDoc == null
          ? cur.playerByUuid
          : {...cur.playerByUuid, ...playerDoc},
      opponentByUuid: oppDoc == null
          ? cur.opponentByUuid
          : {...cur.opponentByUuid, ...oppDoc},
      opponentPaperSubmitted: opponentPaper,
    );
    unawaited(_persistSnapshot());
  }

  Map<String, String> _responsesFromList(
    Object? raw,
    List<TestQuestion> questions,
  ) {
    final byQuestion = <String, String>{};
    if (raw is List) {
      for (var i = 0; i < raw.length && i < questions.length; i++) {
        final mapped = BattleRoomRepository.legacyResponseIntToOption(raw[i]);
        if (mapped != null) {
          byQuestion[questions[i].uuid] = mapped;
        }
      }
    }
    return byQuestion;
  }

  Future<void> _persistSnapshot() async {
    final cur = state;
    if (cur == null) return;
    try {
      final prefs = await ref.read(prefsServiceProvider.future);
      prefs.battleSpectateRecoveryJson = jsonEncode({
        'sessionId': cur.sessionId,
        'playerId': cur.playerId,
        'opponentId': cur.opponentId,
        'playerName': cur.playerName,
        'opponentName': cur.opponentName,
        'playerPhotoUrl': cur.playerPhotoUrl,
        'deadline': cur.deadline.toIso8601String(),
        'playerByUuid': cur.playerByUuid,
        'opponentByUuid': cur.opponentByUuid,
        'opponentPaperSubmitted': cur.opponentPaperSubmitted,
      });
    } catch (e, st) {
      debugPrint('BattleSpectateNotifier._persistSnapshot: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> _clearPrefs() async {
    try {
      final prefs = await ref.read(prefsServiceProvider.future);
      prefs.battleSpectateRecoveryJson = null;
    } catch (_) {}
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    state = null;
    unawaited(_clearPrefs());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final battleSpectateProvider =
    StateNotifierProvider<BattleSpectateNotifier, BattleSpectateState?>((ref) {
      ref.keepAlive();
      final notifier = BattleSpectateNotifier(ref);
      notifier.scheduleRestoreFromPrefs();
      return notifier;
    });
