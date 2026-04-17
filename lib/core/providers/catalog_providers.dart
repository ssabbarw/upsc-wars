import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/entities/subject_info.dart';
import '../domain/entities/topic_info.dart';
import '../domain/repositories/create_session_repository.dart';
import '../domain/repositories/test_catalog_repository.dart';
import '../../features/subject_test/data/repositories/test_catalog_repository_impl.dart';
import '../../features/subject_test/domain/usecases/get_subject_list_use_case.dart';
import '../../features/test_engine/data/repositories/create_session_repository_impl.dart';
import '../../features/test_engine/domain/usecases/create_session_use_case.dart';
import '../../features/history/data/repositories/session_history_repository_impl.dart';
import '../../features/history/domain/repositories/session_history_repository.dart';
import '../../features/history/domain/usecases/get_daily_progress_use_case.dart';
import '../../features/history/domain/usecases/get_session_list_use_case.dart';
import '../../features/history/domain/usecases/get_session_result_use_case.dart';
import '../domain/entities/session_result.dart';
import '../domain/entities/session_summary.dart';
import '../../features/test_engine/data/repositories/test_engine_repository_impl.dart';
import '../../features/test_engine/domain/repositories/test_engine_repository.dart';
import '../../features/test_engine/domain/usecases/flag_question_use_case.dart';
import '../../features/test_engine/domain/usecases/handle_timed_out_question_use_case.dart';
import '../../features/test_engine/domain/usecases/load_session_use_case.dart';
import '../../features/test_engine/domain/usecases/mark_session_abandoned_use_case.dart';
import '../../features/test_engine/domain/usecases/submit_session_use_case.dart';
import '../../features/test_engine/domain/usecases/update_question_attempt_use_case.dart';
import '../../features/test_engine/domain/usecases/update_question_time_use_case.dart';
import '../../features/topic_test/domain/usecases/get_topic_list_use_case.dart';

import '../../features/revision_queue/data/repositories/revision_repository_impl.dart';
import '../../features/revision_queue/domain/repositories/revision_repository.dart';
import '../../features/revision_queue/domain/usecases/get_revision_queue_use_case.dart';
import '../../features/revision_queue/domain/usecases/update_revision_queue_progress_use_case.dart';
import '../domain/entities/weak_concept_group.dart';
import '../domain/entities/trap_pattern_group.dart';
import '../../features/bookmarks/data/repositories/bookmarks_repository_impl.dart';
import '../../features/bookmarks/domain/repositories/bookmarks_repository.dart';
import '../../features/bookmarks/domain/usecases/get_bookmarks_use_case.dart';
import '../../features/bookmarks/domain/usecases/add_bookmark_use_case.dart';
import '../../features/bookmarks/domain/usecases/remove_bookmark_use_case.dart';
import '../../features/home/domain/usecases/get_home_state_use_case.dart';
import '../../features/home/domain/usecases/update_streak_use_case.dart';
import '../domain/entities/home_state.dart';
import '../domain/entities/revision_queue_item.dart';
import '../domain/entities/bookmark_item.dart';
import 'prefs_provider.dart';
import 'user_database_provider.dart';

part 'catalog_providers.g.dart';

@Riverpod(keepAlive: true)
Future<TestCatalogRepository> testCatalogRepository(Ref ref) async {
  return TestCatalogRepositoryImpl(
    userDatabase: ref.watch(userDatabaseProvider),
  );
}

@Riverpod(keepAlive: true)
Future<GetSubjectListUseCase> getSubjectListUseCase(Ref ref) async {
  final repo = await ref.watch(testCatalogRepositoryProvider.future);
  return GetSubjectListUseCase(repo);
}

@Riverpod(keepAlive: true)
Future<GetTopicListUseCase> getTopicListUseCase(Ref ref) async {
  final repo = await ref.watch(testCatalogRepositoryProvider.future);
  return GetTopicListUseCase(repo);
}

@Riverpod(keepAlive: true)
Future<CreateSessionRepository> createSessionRepository(Ref ref) async {
  return CreateSessionRepositoryImpl(
    userDatabase: ref.watch(userDatabaseProvider),
  );
}

@Riverpod(keepAlive: true)
Future<CreateSessionUseCase> createSessionUseCase(Ref ref) async {
  final repo = await ref.watch(createSessionRepositoryProvider.future);
  return CreateSessionUseCase(repo);
}

@Riverpod(keepAlive: true)
Future<String> appLanguage(Ref ref) async {
  final prefs = await ref.watch(prefsServiceProvider.future);
  return prefs.language;
}

@riverpod
Future<List<SubjectInfo>> subjectTestList(Ref ref) async {
  final lang = await ref.watch(appLanguageProvider.future);
  final uc = await ref.watch(getSubjectListUseCaseProvider.future);
  return uc.execute(lang);
}

@riverpod
Future<List<TopicInfo>> topicTestTopics(Ref ref, String subject) async {
  final lang = await ref.watch(appLanguageProvider.future);
  final uc = await ref.watch(getTopicListUseCaseProvider.future);
  return uc.execute(subject, lang);
}


@Riverpod(keepAlive: true)
Future<TestEngineRepository> testEngineRepository(Ref ref) async {
  final prefs = await ref.watch(prefsServiceProvider.future);
  return TestEngineRepositoryImpl(
    userDb: ref.watch(userDatabaseProvider),
    prefsService: prefs,
  );
}

@Riverpod(keepAlive: true)
Future<LoadSessionUseCase> loadSessionUseCase(Ref ref) async {
  final repo = await ref.watch(testEngineRepositoryProvider.future);
  return LoadSessionUseCase(repo);
}

@Riverpod(keepAlive: true)
Future<UpdateQuestionAttemptUseCase> updateQuestionAttemptUseCase(Ref ref) async {
  final repo = await ref.watch(testEngineRepositoryProvider.future);
  return UpdateQuestionAttemptUseCase(repo);
}

@Riverpod(keepAlive: true)
Future<UpdateQuestionTimeUseCase> updateQuestionTimeUseCase(Ref ref) async {
  final repo = await ref.watch(testEngineRepositoryProvider.future);
  return UpdateQuestionTimeUseCase(repo);
}

@Riverpod(keepAlive: true)
Future<FlagQuestionUseCase> flagQuestionUseCase(Ref ref) async {
  final repo = await ref.watch(testEngineRepositoryProvider.future);
  return FlagQuestionUseCase(repo);
}

@Riverpod(keepAlive: true)
Future<SubmitSessionUseCase> submitSessionUseCase(Ref ref) async {
  final repo = await ref.watch(testEngineRepositoryProvider.future);
  return SubmitSessionUseCase(repo);
}

@Riverpod(keepAlive: true)
Future<HandleTimedOutQuestionUseCase> handleTimedOutQuestionUseCase(Ref ref) async {
  final repo = await ref.watch(testEngineRepositoryProvider.future);
  return HandleTimedOutQuestionUseCase(repo);
}

@Riverpod(keepAlive: true)
Future<MarkSessionAbandonedUseCase> markSessionAbandonedUseCase(Ref ref) async {
  final repo = await ref.watch(testEngineRepositoryProvider.future);
  return MarkSessionAbandonedUseCase(repo);
}


@Riverpod(keepAlive: true)
SessionHistoryRepository sessionHistoryRepository(Ref ref) {
  return SessionHistoryRepositoryImpl(ref.watch(userDatabaseProvider));
}

@Riverpod(keepAlive: true)
GetSessionResultUseCase getSessionResultUseCase(Ref ref) {
  return GetSessionResultUseCase(ref.watch(sessionHistoryRepositoryProvider));
}

@Riverpod(keepAlive: true)
GetSessionListUseCase getSessionListUseCase(Ref ref) {
  return GetSessionListUseCase(ref.watch(sessionHistoryRepositoryProvider));
}

@Riverpod(keepAlive: true)
GetDailyProgressUseCase getDailyProgressUseCase(Ref ref) {
  return GetDailyProgressUseCase(ref.watch(sessionHistoryRepositoryProvider));
}

@riverpod
Future<SessionResult> sessionResult(Ref ref, String sessionId) async {
  final uc = ref.watch(getSessionResultUseCaseProvider);
  return uc.execute(sessionId);
}

@riverpod
Future<List<SessionSummary>> sessionSummaries(
  Ref ref, {
  String? subject,
  String? mode,
}) async {
  final uc = ref.watch(getSessionListUseCaseProvider);
  return uc.execute(subject: subject, mode: mode);
}

@riverpod
Future<int> dailyProgressCount(Ref ref) async {
  final uc = ref.watch(getDailyProgressUseCaseProvider);
  return uc.execute(DateTime.now());
}


@Riverpod(keepAlive: true)
Future<RevisionRepository> revisionRepository(Ref ref) async {
  return RevisionRepositoryImpl(userDb: ref.watch(userDatabaseProvider));
}

@Riverpod(keepAlive: true)
Future<GetRevisionQueueUseCase> getRevisionQueueUseCase(Ref ref) async {
  final repo = await ref.watch(revisionRepositoryProvider.future);
  return GetRevisionQueueUseCase(repo);
}

@Riverpod(keepAlive: true)
Future<UpdateRevisionQueueProgressUseCase> updateRevisionQueueProgressUseCase(Ref ref) async {
  final repo = await ref.watch(revisionRepositoryProvider.future);
  return UpdateRevisionQueueProgressUseCase(repo);
}

@Riverpod(keepAlive: true)
Future<BookmarksRepository> bookmarksRepository(Ref ref) async {
  return BookmarksRepositoryImpl(userDb: ref.watch(userDatabaseProvider));
}

@Riverpod(keepAlive: true)
Future<GetBookmarksUseCase> getBookmarksUseCase(Ref ref) async {
  final repo = await ref.watch(bookmarksRepositoryProvider.future);
  return GetBookmarksUseCase(repo);
}

@Riverpod(keepAlive: true)
Future<AddBookmarkUseCase> addBookmarkUseCase(Ref ref) async {
  final repo = await ref.watch(bookmarksRepositoryProvider.future);
  return AddBookmarkUseCase(repo);
}

@Riverpod(keepAlive: true)
Future<RemoveBookmarkUseCase> removeBookmarkUseCase(Ref ref) async {
  final repo = await ref.watch(bookmarksRepositoryProvider.future);
  return RemoveBookmarkUseCase(repo);
}

@Riverpod(keepAlive: true)
Future<GetHomeStateUseCase> getHomeStateUseCase(Ref ref) async {
  final prefs = await ref.watch(prefsServiceProvider.future);
  return GetHomeStateUseCase(
    prefs: prefs,
    daily: ref.watch(getDailyProgressUseCaseProvider),
    revision: await ref.watch(getRevisionQueueUseCaseProvider.future),
    bookmarks: await ref.watch(getBookmarksUseCaseProvider.future),
    sessions: ref.watch(getSessionListUseCaseProvider),
  );
}

@Riverpod(keepAlive: true)
Future<UpdateStreakUseCase> updateStreakUseCase(Ref ref) async {
  final prefs = await ref.watch(prefsServiceProvider.future);
  return UpdateStreakUseCase(prefs);
}

@riverpod
Future<List<RevisionQueueItem>> revisionQueueItems(Ref ref) async {
  final uc = await ref.watch(getRevisionQueueUseCaseProvider.future);
  return uc.execute();
}

@riverpod
Future<List<WeakSubTopicGroup>> weakSubTopicGroups(Ref ref) async {
  final repo = await ref.watch(revisionRepositoryProvider.future);
  return repo.getWeakSubTopicGroups();
}

@riverpod
Future<List<TrapPatternGroup>> weakTrapGroups(Ref ref) async {
  final repo = await ref.watch(revisionRepositoryProvider.future);
  return repo.getWeakTrapGroups();
}

@riverpod
Future<List<BookmarkItem>> bookmarksList(Ref ref) async {
  final uc = await ref.watch(getBookmarksUseCaseProvider.future);
  return uc.execute();
}

@riverpod
Future<HomeState> homeState(Ref ref) async {
  final uc = await ref.watch(getHomeStateUseCaseProvider.future);
  return uc.execute();
}

@riverpod
Future<int> totalQuestionCount(Ref ref) async {
  final db = ref.watch(userDatabaseProvider);
  return db.questionsDao.getTotalQuestionCount();
}
