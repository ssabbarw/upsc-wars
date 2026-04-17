import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:upsc_wars/core/domain/entities/active_session.dart';
import 'package:upsc_wars/core/domain/errors/app_errors.dart';
import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/core/providers/catalog_providers.dart';
import 'package:upsc_wars/features/battle/domain/battle_scoring.dart';
import 'package:upsc_wars/features/battle/domain/entities/battle_participant.dart';
import 'package:upsc_wars/features/battle/domain/entities/battle_result_payload.dart';
import 'package:upsc_wars/features/battle/domain/entities/battle_session.dart';
import 'package:upsc_wars/features/battle/data/battle_firestore_paths.dart';
import 'package:upsc_wars/features/battle/data/battle_match_firestore_service.dart';
import 'package:upsc_wars/features/battle/data/battle_room_repository.dart';
import 'package:upsc_wars/features/battle/domain/battle_opponent_policy.dart';
import 'package:upsc_wars/features/battle/domain/services/battle_name_service.dart';
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
    required this.totalElapsedSecs,
    required this.bookmarkedByUuid,
    required this.waitingForGuestToJoin,
  });

  factory BattleSessionUiState.initial() {
    return const BattleSessionUiState(
      isLoading: true,
      isSubmitting: false,
      currentIndex: 0,
      battleSession: null,
      roomId: null,
      errorMessage: null,
      totalElapsedSecs: 0,
      bookmarkedByUuid: {},
      waitingForGuestToJoin: false,
    );
  }

  final bool isLoading;
  final bool isSubmitting;
  final int currentIndex;
  final BattleSession? battleSession;
  final String? roomId;
  final String? errorMessage;
  final int totalElapsedSecs;
  final Map<String, bool> bookmarkedByUuid;
  final bool waitingForGuestToJoin;

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
    int? totalElapsedSecs,
    Map<String, bool>? bookmarkedByUuid,
    bool? waitingForGuestToJoin,
  }) {
    return BattleSessionUiState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      currentIndex: currentIndex ?? this.currentIndex,
      battleSession: battleSession ?? this.battleSession,
      roomId: roomId ?? this.roomId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      totalElapsedSecs: totalElapsedSecs ?? this.totalElapsedSecs,
      bookmarkedByUuid: bookmarkedByUuid ?? this.bookmarkedByUuid,
      waitingForGuestToJoin:
          waitingForGuestToJoin ?? this.waitingForGuestToJoin,
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
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _matchSub;
  final BattleRoomRepository _roomRepository = const BattleRoomRepository();

  Future<void> _init() async {
    try {
      final base = await _loadSessionWithRetry();
      final user = ref.read(authStateChangesProvider).asData?.value;
      final playerId = (user?.email ?? user?.uid ?? 'player').toLowerCase();
      final photo = user?.photoURL?.trim();
      final repo = await ref.read(testEngineRepositoryProvider.future);
      final bookmarked = <String, bool>{};
      for (final q in base.questions) {
        bookmarked[q.uuid] = await repo.isBookmarked(q.uuid);
      }
      var totalElapsed = 0;
      if (base.mode == 'exam' &&
          base.isTimed &&
          base.timeLimitSecs != null) {
        final saved = base.savedExamRemainingSecs;
        if (saved != null) {
          totalElapsed = (base.timeLimitSecs! - saved).clamp(
            0,
            base.timeLimitSecs!,
          );
        }
      }

      final matchSnap = await BattleFirestorePaths.matchDoc(sessionId).get();
      final questionUuids = base.questions.map((q) => q.uuid).toList();

      var opponentId = BattleOpponentPolicy.syntheticBotDocId;
      var opponentName = _opponentDisplayName(sessionId);
      var humanLobbyWaiting = false;

      if (matchSnap.exists) {
        final d = matchSnap.data()!;
        final mode = d['battle_mode'] as String?;
        if (mode == BattleMatchFirestoreService.battleModeHuman) {
          final host = (d['host_email'] as String?)?.toLowerCase() ?? '';
          final guest = (d['guest_email'] as String?)?.toLowerCase() ?? '';
          if (playerId == host && guest.isNotEmpty) {
            opponentId = guest;
            final gn = (d['guest_display_name'] as String?)?.trim();
            opponentName =
                (gn != null && gn.isNotEmpty) ? gn : 'Opponent';
          } else if (playerId == guest && host.isNotEmpty) {
            opponentId = host;
            final hn = (d['host_display_name'] as String?)?.trim();
            opponentName =
                (hn != null && hn.isNotEmpty) ? hn : 'Opponent';
          }
          humanLobbyWaiting =
              opponentId != BattleOpponentPolicy.syntheticBotDocId &&
              !_matchDocLetsStartGame(d);
        }
      } else {
        const svc = BattleMatchFirestoreService();
        await svc.createBotMatch(
          sessionId: sessionId,
          questionUuids: questionUuids,
          hostEmail: playerId,
          hostDisplayName: user?.displayName ?? 'You',
          hostPhotoUrl: user?.photoURL,
          opponentDocId: BattleOpponentPolicy.syntheticBotDocId,
          opponentDisplayName: _opponentDisplayName(sessionId),
          subject: base.subject,
        );
      }

      final battle = BattleSession(
        id: sessionId,
        baseSession: base,
        player: BattleParticipant(
          id: playerId,
          displayName: user?.displayName ?? 'You',
          photoUrl: (photo == null || photo.isEmpty) ? null : photo,
        ),
        opponent: BattleParticipant(
          id: opponentId,
          displayName: opponentName,
        ),
        playerResponsesByQuestion: _playerResponsesFromSession(base),
        opponentResponsesByQuestion: const <String, String>{},
      );
      _listenToParticipants(roomId: sessionId, base: battle);
      state = state.copyWith(
        isLoading: false,
        battleSession: battle,
        roomId: sessionId,
        currentIndex: _startIndex(base),
        totalElapsedSecs: totalElapsed,
        bookmarkedByUuid: bookmarked,
        waitingForGuestToJoin: humanLobbyWaiting,
        clearError: true,
      );
      if (humanLobbyWaiting) {
        _listenMatchLobby();
      }
      if (opponentId == BattleOpponentPolicy.syntheticBotDocId) {
        _scheduleBotAnswerForCurrentQuestion();
      }
    } catch (error, stackTrace) {
      debugPrint('BattleSessionController._init failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyStartError(error),
      );
    }
  }

  Future<ActiveSession> _loadSessionWithRetry() async {
    final load = await ref.read(loadSessionUseCaseProvider.future);
    const maxAttempts = 4;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await load.execute(sessionId);
      } catch (error) {
        final isNotFound = error is SessionNotFoundException;
        if (!isNotFound || attempt == maxAttempts) rethrow;
        debugPrint(
          'BattleSessionController._loadSessionWithRetry waiting '
          '(attempt $attempt/$maxAttempts) for session $sessionId',
        );
        await Future.delayed(Duration(milliseconds: attempt * 250));
      }
    }
    throw const SessionNotFoundException();
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
    if (state.waitingForGuestToJoin) {
      state = state.copyWith(
        errorMessage: 'Waiting for your opponent to join…',
      );
      return;
    }
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

  void jumpToIndex(int index) {
    final current = state.battleSession;
    if (current == null) return;
    if (index < 0 || index >= current.baseSession.questions.length) return;
    state = state.copyWith(currentIndex: index, clearError: true);
    _scheduleBotAnswerForCurrentQuestion();
  }

  void tickSecond() {
    final current = state.battleSession;
    if (current == null) return;
    final s = current.baseSession;
    if (!s.isTimed || s.timeLimitSecs == null) return;
    final next = state.totalElapsedSecs + 1;
    state = state.copyWith(totalElapsedSecs: next, clearError: true);
    if (next > 0 && next % 10 == 0) {
      final remain = (s.timeLimitSecs! - next).clamp(0, s.timeLimitSecs!);
      unawaited(_persistExamRemaining(remain));
    }
  }

  Future<void> _persistExamRemaining(int remainingSecs) async {
    try {
      final repo = await ref.read(testEngineRepositoryProvider.future);
      await repo.saveExamRemainingSeconds(
        sessionId: sessionId,
        remainingSecs: remainingSecs,
      );
    } catch (_) {}
  }

  Future<bool> toggleBookmark() async {
    final current = state.battleSession;
    if (current == null) return false;
    final q = current.baseSession.questions[state.currentIndex];
    final isMarked = state.bookmarkedByUuid[q.uuid] ?? false;
    try {
      final repo = await ref.read(testEngineRepositoryProvider.future);
      if (isMarked) {
        await repo.removeBookmark(q.uuid);
      } else {
        await repo.addBookmark(q.uuid);
      }
      final nextMap = {...state.bookmarkedByUuid, q.uuid: !isMarked};
      state = state.copyWith(bookmarkedByUuid: nextMap, clearError: true);
      return !isMarked;
    } catch (_) {
      return isMarked;
    }
  }

  Future<void> toggleFlag() async {
    final current = state.battleSession;
    if (current == null) return;
    final q = current.baseSession.questions[state.currentIndex];
    final next = !q.flagged;
    try {
      final uc = await ref.read(flagQuestionUseCaseProvider.future);
      await uc.execute(sessionId: sessionId, questionUuid: q.uuid, flagged: next);
      final updated = [...current.baseSession.questions];
      updated[state.currentIndex] = q.copyWith(flagged: next);
      state = state.copyWith(
        battleSession: current.copyWith(
          baseSession: _copySession(current.baseSession, updated),
        ),
        clearError: true,
      );
    } catch (_) {}
  }

  Future<void> markAbandoned() async {
    try {
      final uc = await ref.read(markSessionAbandonedUseCaseProvider.future);
      await uc.execute(sessionId);
    } catch (_) {}
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

  BattleResultPayload? buildResultPayload() {
    final current = state.battleSession;
    if (current == null) return null;
    final player = state.playerScore;
    final opponent = state.opponentScore;
    if (player == null || opponent == null) return null;

    bool? outcomeForQuestion(String? selected, String correct) {
      if (selected == null) return null;
      return selected.toLowerCase() == correct.toLowerCase();
    }

    final playerOutcomes = current.baseSession.questions
        .map(
          (q) => outcomeForQuestion(
            current.playerResponsesByQuestion[q.uuid],
            q.correctOption,
          ),
        )
        .toList();
    final opponentOutcomes = current.baseSession.questions
        .map(
          (q) => outcomeForQuestion(
            current.opponentResponsesByQuestion[q.uuid],
            q.correctOption,
          ),
        )
        .toList();
    return BattleResultPayload(
      sessionId: sessionId,
      playerName: current.player.displayName,
      opponentName: current.opponent.displayName,
      playerScore: player.points,
      opponentScore: opponent.points,
      playerOutcomeByQuestion: playerOutcomes,
      opponentOutcomeByQuestion: opponentOutcomes,
    );
  }

  void _scheduleBotAnswerForCurrentQuestion() {
    final current = state.battleSession;
    if (current == null) return;
    if (!BattleOpponentPolicy.isBotOpponent(current.opponent.id)) return;
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
      unawaited(
        _commitBotAnswer(
          roomId: roomId,
          question: q,
          selectedOption: plan.selectedOption,
        ),
      );
    });
  }

  Future<void> _commitBotAnswer({
    required String roomId,
    required TestQuestion question,
    required String selectedOption,
  }) async {
    final latest = state.battleSession;
    if (latest == null) return;
    if (latest.opponentResponsesByQuestion.containsKey(question.uuid)) {
      return;
    }
    try {
      await _writeParticipantResponse(
        roomId: roomId,
        participantId: latest.opponent.id,
        questionUuid: question.uuid,
        selectedOption: selectedOption,
      );
      final cur = state.battleSession;
      if (cur == null) return;
      if (cur.opponentResponsesByQuestion.containsKey(question.uuid)) {
        return;
      }
      final merged = {
        ...cur.opponentResponsesByQuestion,
        question.uuid: selectedOption,
      };
      state = state.copyWith(
        battleSession: cur.copyWith(
          opponentResponsesByQuestion: merged,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('BattleSessionController._commitBotAnswer failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _listenToParticipants({
    required String roomId,
    required BattleSession base,
  }) {
    final colRef = BattleFirestorePaths.joinedUsersCol(roomId);
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
      final playerResponses = _responsesFromList(
        playerDoc?.data()['responses'],
        base.baseSession.questions,
      );
      final opponentResponses = _responsesFromList(
        opponentDoc?.data()['responses'],
        base.baseSession.questions,
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

  Map<String, String> _responsesFromList(
    Object? raw,
    List<TestQuestion> questions,
  ) {
    final byQuestion = <String, String>{};
    if (raw is List) {
      for (var i = 0; i < raw.length && i < questions.length; i++) {
        final val = raw[i];
        final mapped = BattleRoomRepository.legacyResponseIntToOption(val);
        if (mapped != null) {
          byQuestion[questions[i].uuid] = mapped;
        }
      }
    }
    return byQuestion;
  }

  Future<void> _writeParticipantResponse({
    required String roomId,
    required String participantId,
    required String questionUuid,
    required String selectedOption,
  }) async {
    try {
      final current = state.battleSession;
      if (current == null) return;
      final merged = participantId == current.player.id
          ? {...current.playerResponsesByQuestion, questionUuid: selectedOption}
          : {
              ...current.opponentResponsesByQuestion,
              questionUuid: selectedOption,
            };
      await _roomRepository.upsertParticipantResponses(
        sessionId: roomId,
        participantDocId: participantId,
        questions: current.baseSession.questions,
        responsesByQuestionUuid: merged,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'BattleSessionController._writeParticipantResponse failed: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  void _listenMatchLobby() {
    _matchSub?.cancel();
    _matchSub = BattleFirestorePaths.matchDoc(sessionId).snapshots().listen((
      snap,
    ) {
      if (!snap.exists) return;
      final lets = _matchDocLetsStartGame(snap.data());
      final waiting = !lets;
      if (state.waitingForGuestToJoin != waiting) {
        state = state.copyWith(
          waitingForGuestToJoin: waiting,
          clearError: !waiting,
        );
      }
    });
  }

  String _opponentDisplayName(String seed) {
    return BattleNameService.pickFromSeed(seed);
  }

  String _friendlyStartError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('permission-denied')) {
      return 'Battle permission denied by Firestore rules.';
    }
    if (message.contains('unavailable') || message.contains('network')) {
      return 'Network unavailable. Please check internet and retry.';
    }
    return 'Could not start online battle. Please retry.';
  }

  @override
  void dispose() {
    _participantsSub?.cancel();
    _matchSub?.cancel();
    for (final timer in _botTimersByQuestion.values) {
      timer.cancel();
    }
    _botTimersByQuestion.clear();
    super.dispose();
  }
}

bool _matchDocLetsStartGame(Map<String, dynamic>? data) {
  if (data == null) return true;
  final v = data['lets_start_game'];
  if (v is bool) return v;
  return true;
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
