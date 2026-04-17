import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:upsc_wars/core/domain/entities/active_session.dart';
import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/core/providers/catalog_providers.dart';
import 'package:upsc_wars/features/battle/domain/battle_scoring.dart';
import 'package:upsc_wars/features/battle/domain/entities/battle_participant.dart';
import 'package:upsc_wars/features/battle/domain/entities/battle_session.dart';
import 'package:upsc_wars/features/battle/domain/services/bot_battle_service.dart';
import 'package:upsc_wars/features/home/providers/auth_providers.dart';

final botBattleServiceProvider = Provider<BotBattleService>(
  (ref) => const BotBattleService(),
);

class BattleSessionUiState {
  const BattleSessionUiState({
    required this.isLoading,
    required this.isSubmitting,
    required this.currentIndex,
    required this.battleSession,
    required this.roomId,
    required this.errorMessage,
  });

  factory BattleSessionUiState.initial() {
    return const BattleSessionUiState(
      isLoading: true,
      isSubmitting: false,
      currentIndex: 0,
      battleSession: null,
      roomId: null,
      errorMessage: null,
    );
  }

  final bool isLoading;
  final bool isSubmitting;
  final int currentIndex;
  final BattleSession? battleSession;
  final String? roomId;
  final String? errorMessage;

  BattleScore? get playerScore {
    final current = battleSession;
    if (current == null) return null;
    return calculateUpscBattleScore(
      questions: current.baseSession.questions,
      selectedOptionByQuestion: current.playerResponsesByQuestion,
    );
  }

  BattleScore? get opponentScore {
    final current = battleSession;
    if (current == null) return null;
    return calculateUpscBattleScore(
      questions: current.baseSession.questions,
      selectedOptionByQuestion: current.opponentResponsesByQuestion,
    );
  }

  BattleSessionUiState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    int? currentIndex,
    BattleSession? battleSession,
    String? roomId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BattleSessionUiState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      currentIndex: currentIndex ?? this.currentIndex,
      battleSession: battleSession ?? this.battleSession,
      roomId: roomId ?? this.roomId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class BattleSessionController extends StateNotifier<BattleSessionUiState> {
  BattleSessionController(this.ref, this.sessionId)
    : super(BattleSessionUiState.initial()) {
    _init();
  }

  final Ref ref;
  final String sessionId;
  final Map<String, Timer> _botTimersByQuestion = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _participantsSub;

  static const _roomsCollection = 'battle_rooms';
  static const _participantsSubCollection = 'participants';
  static const _opponentId = 'opponent';

  Future<void> _init() async {
    try {
      final load = await ref.read(loadSessionUseCaseProvider.future);
      final base = await load.execute(sessionId);
      final user = ref.read(authStateChangesProvider).asData?.value;
      final battle = BattleSession(
        id: sessionId,
        baseSession: base,
        player: BattleParticipant(
          id: user?.uid ?? 'player',
          displayName: user?.displayName ?? 'You',
        ),
        opponent: BattleParticipant(
          id: _opponentId,
          displayName: _opponentDisplayName(sessionId),
        ),
        playerResponsesByQuestion: _playerResponsesFromSession(base),
        opponentResponsesByQuestion: const <String, String>{},
      );
      final roomId = await _createRoom(
        sessionId: sessionId,
        questionUuids: base.questions.map((q) => q.uuid).toList(),
        player: battle.player,
        opponent: battle.opponent,
      );
      _listenToParticipants(roomId: roomId, base: battle);
      state = state.copyWith(
        isLoading: false,
        battleSession: battle,
        roomId: roomId,
        currentIndex: _startIndex(base),
        clearError: true,
      );
      _scheduleBotAnswerForCurrentQuestion();
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Could not start online battle. Please check internet and retry.',
      );
    }
  }

  int _startIndex(ActiveSession session) {
    final firstUnattempted = session.questions.indexWhere(
      (q) => q.status == 'unattempted',
    );
    return firstUnattempted == -1 ? 0 : firstUnattempted;
  }

  Map<String, String> _playerResponsesFromSession(ActiveSession session) {
    final byQuestion = <String, String>{};
    for (final q in session.questions) {
      if (q.selectedOption == null) continue;
      byQuestion[q.uuid] = q.selectedOption!;
    }
    return byQuestion;
  }

  Future<void> selectOption(String option) async {
    final current = state.battleSession;
    if (current == null) return;
    final roomId = state.roomId;
    if (roomId == null) return;
    final index = state.currentIndex;
    final question = current.baseSession.questions[index];
    if (current.playerResponsesByQuestion.containsKey(question.uuid)) return;

    try {
      final uc = await ref.read(updateQuestionAttemptUseCaseProvider.future);
      final isCorrect = await uc.execute(
        sessionId: sessionId,
        questionUuid: question.uuid,
        selectedOption: option,
      );
      final updatedQuestions = [...current.baseSession.questions];
      updatedQuestions[index] = question.copyWith(
        selectedOption: option.toLowerCase(),
        status: isCorrect ? 'correct' : 'wrong',
      );
      final updatedPlayerAnswers = {...current.playerResponsesByQuestion};
      updatedPlayerAnswers[question.uuid] = option.toLowerCase();
      await _writeParticipantResponse(
        roomId: roomId,
        participantId: current.player.id,
        questionUuid: question.uuid,
        selectedOption: option.toLowerCase(),
      );

      state = state.copyWith(
        battleSession: current.copyWith(
          baseSession: _copySession(current.baseSession, updatedQuestions),
          playerResponsesByQuestion: updatedPlayerAnswers,
        ),
        clearError: true,
      );
      _scheduleBotAnswerForCurrentQuestion();
    } catch (_) {
      state = state.copyWith(errorMessage: 'Could not record your answer.');
    }
  }

  void moveNext() {
    final current = state.battleSession;
    if (current == null) return;
    if (state.currentIndex >= current.baseSession.questions.length - 1) return;
    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      clearError: true,
    );
    _scheduleBotAnswerForCurrentQuestion();
  }

  void movePrev() {
    final current = state.battleSession;
    if (current == null) return;
    if (state.currentIndex == 0) return;
    state = state.copyWith(
      currentIndex: state.currentIndex - 1,
      clearError: true,
    );
    _scheduleBotAnswerForCurrentQuestion();
  }

  Future<String> submit() async {
    final current = state.battleSession;
    if (current == null) throw StateError('No battle session');
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final uc = await ref.read(submitSessionUseCaseProvider.future);
      final resultId = await uc.execute(sessionId);
      state = state.copyWith(isSubmitting: false, clearError: true);
      return resultId;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Could not submit battle.',
      );
      rethrow;
    }
  }

  void _scheduleBotAnswerForCurrentQuestion() {
    final current = state.battleSession;
    if (current == null) return;
    final roomId = state.roomId;
    if (roomId == null) return;
    final q = current.baseSession.questions[state.currentIndex];
    if (current.opponentResponsesByQuestion.containsKey(q.uuid)) return;
    if (_botTimersByQuestion.containsKey(q.uuid)) return;

    final botService = ref.read(botBattleServiceProvider);
    final plan = botService.buildPlan(
      sessionId: current.id,
      questionIndex: state.currentIndex,
      question: q,
    );
    _botTimersByQuestion[q.uuid] = Timer(plan.delay, () {
      _botTimersByQuestion.remove(q.uuid);
      final latest = state.battleSession;
      if (latest == null) return;
      if (latest.opponentResponsesByQuestion.containsKey(q.uuid)) return;
      _writeParticipantResponse(
        roomId: roomId,
        participantId: latest.opponent.id,
        questionUuid: q.uuid,
        selectedOption: plan.selectedOption,
      );
    });
  }

  Future<String> _createRoom({
    required String sessionId,
    required List<String> questionUuids,
    required BattleParticipant player,
    required BattleParticipant opponent,
  }) async {
    final roomRef = FirebaseFirestore.instance
        .collection(_roomsCollection)
        .doc(sessionId);
    final now = DateTime.now().millisecondsSinceEpoch;
    await roomRef
        .set({
          'sessionId': sessionId,
          'status': 'active',
          'createdAt': now,
          'questionUuids': questionUuids,
        })
        .timeout(const Duration(seconds: 8));
    await roomRef
        .collection(_participantsSubCollection)
        .doc(player.id)
        .set({
          'displayName': player.displayName,
          'isBot': false,
          'updatedAt': now,
          'responses': <String, String>{},
        })
        .timeout(const Duration(seconds: 8));
    await roomRef
        .collection(_participantsSubCollection)
        .doc(opponent.id)
        .set({
          'displayName': opponent.displayName,
          'isBot': true,
          'updatedAt': now,
          'responses': <String, String>{},
        })
        .timeout(const Duration(seconds: 8));
    return roomRef.id;
  }

  void _listenToParticipants({
    required String roomId,
    required BattleSession base,
  }) {
    final colRef = FirebaseFirestore.instance
        .collection(_roomsCollection)
        .doc(roomId)
        .collection(_participantsSubCollection);
    _participantsSub?.cancel();
    _participantsSub = colRef.snapshots().listen((snapshot) {
      final docs = snapshot.docs;
      if (docs.isEmpty) return;
      QueryDocumentSnapshot<Map<String, dynamic>>? playerDoc;
      QueryDocumentSnapshot<Map<String, dynamic>>? opponentDoc;
      for (final doc in docs) {
        if (doc.id == base.player.id) playerDoc = doc;
        if (doc.id == base.opponent.id) opponentDoc = doc;
      }
      final playerResponses = _responsesFromMap(playerDoc?.data()['responses']);
      final opponentResponses = _responsesFromMap(
        opponentDoc?.data()['responses'],
      );

      final current = state.battleSession;
      if (current == null) return;
      state = state.copyWith(
        battleSession: current.copyWith(
          playerResponsesByQuestion: playerResponses,
          opponentResponsesByQuestion: opponentResponses,
        ),
      );
    });
  }

  Map<String, String> _responsesFromMap(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return raw.map((key, value) => MapEntry(key, value.toString()));
    }
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }
    return const <String, String>{};
  }

  Future<void> _writeParticipantResponse({
    required String roomId,
    required String participantId,
    required String questionUuid,
    required String selectedOption,
  }) async {
    await FirebaseFirestore.instance
        .collection(_roomsCollection)
        .doc(roomId)
        .collection(_participantsSubCollection)
        .doc(participantId)
        .set({
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
          'responses': {questionUuid: selectedOption},
        }, SetOptions(merge: true));
  }

  String _opponentDisplayName(String seed) {
    const names = <String>[
      'Aspirant_01',
      'UPSC_Warrior',
      'CurrentAffairsAce',
      'PolityNinja',
      'GSMaster',
    ];
    return names[seed.hashCode.abs() % names.length];
  }

  @override
  void dispose() {
    _participantsSub?.cancel();
    for (final timer in _botTimersByQuestion.values) {
      timer.cancel();
    }
    _botTimersByQuestion.clear();
    super.dispose();
  }
}

ActiveSession _copySession(ActiveSession source, List<TestQuestion> questions) {
  return ActiveSession(
    id: source.id,
    mode: source.mode,
    subject: source.subject,
    topic: source.topic,
    subTopic: source.subTopic,
    questionCount: source.questionCount,
    isTimed: source.isTimed,
    timeLimitSecs: source.timeLimitSecs,
    status: source.status,
    language: source.language,
    questions: questions,
    savedExamRemainingSecs: source.savedExamRemainingSecs,
  );
}

final battleSessionProvider = StateNotifierProvider.autoDispose
    .family<BattleSessionController, BattleSessionUiState, String>(
      (ref, sessionId) => BattleSessionController(ref, sessionId),
    );
