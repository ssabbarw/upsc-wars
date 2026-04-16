// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(testCatalogRepository)
final testCatalogRepositoryProvider = TestCatalogRepositoryProvider._();

final class TestCatalogRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<TestCatalogRepository>,
          TestCatalogRepository,
          FutureOr<TestCatalogRepository>
        >
    with
        $FutureModifier<TestCatalogRepository>,
        $FutureProvider<TestCatalogRepository> {
  TestCatalogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'testCatalogRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$testCatalogRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<TestCatalogRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TestCatalogRepository> create(Ref ref) {
    return testCatalogRepository(ref);
  }
}

String _$testCatalogRepositoryHash() =>
    r'c1ade1a947ce8ba35d48874f2c39543da8cc370a';

@ProviderFor(getSubjectListUseCase)
final getSubjectListUseCaseProvider = GetSubjectListUseCaseProvider._();

final class GetSubjectListUseCaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<GetSubjectListUseCase>,
          GetSubjectListUseCase,
          FutureOr<GetSubjectListUseCase>
        >
    with
        $FutureModifier<GetSubjectListUseCase>,
        $FutureProvider<GetSubjectListUseCase> {
  GetSubjectListUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getSubjectListUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getSubjectListUseCaseHash();

  @$internal
  @override
  $FutureProviderElement<GetSubjectListUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GetSubjectListUseCase> create(Ref ref) {
    return getSubjectListUseCase(ref);
  }
}

String _$getSubjectListUseCaseHash() =>
    r'd375ff96cef27b46317ac066e309f8c5eb2a5bd5';

@ProviderFor(getTopicListUseCase)
final getTopicListUseCaseProvider = GetTopicListUseCaseProvider._();

final class GetTopicListUseCaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<GetTopicListUseCase>,
          GetTopicListUseCase,
          FutureOr<GetTopicListUseCase>
        >
    with
        $FutureModifier<GetTopicListUseCase>,
        $FutureProvider<GetTopicListUseCase> {
  GetTopicListUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getTopicListUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getTopicListUseCaseHash();

  @$internal
  @override
  $FutureProviderElement<GetTopicListUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GetTopicListUseCase> create(Ref ref) {
    return getTopicListUseCase(ref);
  }
}

String _$getTopicListUseCaseHash() =>
    r'63c7b6ff3a4f739747a3beb88318e64acc722fb9';

@ProviderFor(createSessionRepository)
final createSessionRepositoryProvider = CreateSessionRepositoryProvider._();

final class CreateSessionRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<CreateSessionRepository>,
          CreateSessionRepository,
          FutureOr<CreateSessionRepository>
        >
    with
        $FutureModifier<CreateSessionRepository>,
        $FutureProvider<CreateSessionRepository> {
  CreateSessionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createSessionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createSessionRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<CreateSessionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CreateSessionRepository> create(Ref ref) {
    return createSessionRepository(ref);
  }
}

String _$createSessionRepositoryHash() =>
    r'7ce4b1b1c7b25023d88433647953cfc757ff0746';

@ProviderFor(createSessionUseCase)
final createSessionUseCaseProvider = CreateSessionUseCaseProvider._();

final class CreateSessionUseCaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<CreateSessionUseCase>,
          CreateSessionUseCase,
          FutureOr<CreateSessionUseCase>
        >
    with
        $FutureModifier<CreateSessionUseCase>,
        $FutureProvider<CreateSessionUseCase> {
  CreateSessionUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createSessionUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createSessionUseCaseHash();

  @$internal
  @override
  $FutureProviderElement<CreateSessionUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CreateSessionUseCase> create(Ref ref) {
    return createSessionUseCase(ref);
  }
}

String _$createSessionUseCaseHash() =>
    r'b34856e40829176d61e237a896baa94e26244da5';

@ProviderFor(appLanguage)
final appLanguageProvider = AppLanguageProvider._();

final class AppLanguageProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  AppLanguageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLanguageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLanguageHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return appLanguage(ref);
  }
}

String _$appLanguageHash() => r'919a6d930784aa911c53da6962bfa08676f67200';

@ProviderFor(subjectTestList)
final subjectTestListProvider = SubjectTestListProvider._();

final class SubjectTestListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SubjectInfo>>,
          List<SubjectInfo>,
          FutureOr<List<SubjectInfo>>
        >
    with
        $FutureModifier<List<SubjectInfo>>,
        $FutureProvider<List<SubjectInfo>> {
  SubjectTestListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subjectTestListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subjectTestListHash();

  @$internal
  @override
  $FutureProviderElement<List<SubjectInfo>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SubjectInfo>> create(Ref ref) {
    return subjectTestList(ref);
  }
}

String _$subjectTestListHash() => r'e72ae03f8849df937eb4a9b3650b04df90bfbb59';

@ProviderFor(topicTestTopics)
final topicTestTopicsProvider = TopicTestTopicsFamily._();

final class TopicTestTopicsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TopicInfo>>,
          List<TopicInfo>,
          FutureOr<List<TopicInfo>>
        >
    with $FutureModifier<List<TopicInfo>>, $FutureProvider<List<TopicInfo>> {
  TopicTestTopicsProvider._({
    required TopicTestTopicsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'topicTestTopicsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$topicTestTopicsHash();

  @override
  String toString() {
    return r'topicTestTopicsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TopicInfo>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TopicInfo>> create(Ref ref) {
    final argument = this.argument as String;
    return topicTestTopics(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TopicTestTopicsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$topicTestTopicsHash() => r'6ac2c4d29f0af742877b65de687526d9b39af214';

final class TopicTestTopicsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TopicInfo>>, String> {
  TopicTestTopicsFamily._()
    : super(
        retry: null,
        name: r'topicTestTopicsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TopicTestTopicsProvider call(String subject) =>
      TopicTestTopicsProvider._(argument: subject, from: this);

  @override
  String toString() => r'topicTestTopicsProvider';
}

@ProviderFor(testEngineRepository)
final testEngineRepositoryProvider = TestEngineRepositoryProvider._();

final class TestEngineRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<TestEngineRepository>,
          TestEngineRepository,
          FutureOr<TestEngineRepository>
        >
    with
        $FutureModifier<TestEngineRepository>,
        $FutureProvider<TestEngineRepository> {
  TestEngineRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'testEngineRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$testEngineRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<TestEngineRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TestEngineRepository> create(Ref ref) {
    return testEngineRepository(ref);
  }
}

String _$testEngineRepositoryHash() =>
    r'd4aae35a23c1fff1c2c45b0d69645c55eb7b6be8';

@ProviderFor(loadSessionUseCase)
final loadSessionUseCaseProvider = LoadSessionUseCaseProvider._();

final class LoadSessionUseCaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<LoadSessionUseCase>,
          LoadSessionUseCase,
          FutureOr<LoadSessionUseCase>
        >
    with
        $FutureModifier<LoadSessionUseCase>,
        $FutureProvider<LoadSessionUseCase> {
  LoadSessionUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loadSessionUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loadSessionUseCaseHash();

  @$internal
  @override
  $FutureProviderElement<LoadSessionUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LoadSessionUseCase> create(Ref ref) {
    return loadSessionUseCase(ref);
  }
}

String _$loadSessionUseCaseHash() =>
    r'f15188d8498f69b9954505c0dd8ec5ac1f0856fe';

@ProviderFor(updateQuestionAttemptUseCase)
final updateQuestionAttemptUseCaseProvider =
    UpdateQuestionAttemptUseCaseProvider._();

final class UpdateQuestionAttemptUseCaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<UpdateQuestionAttemptUseCase>,
          UpdateQuestionAttemptUseCase,
          FutureOr<UpdateQuestionAttemptUseCase>
        >
    with
        $FutureModifier<UpdateQuestionAttemptUseCase>,
        $FutureProvider<UpdateQuestionAttemptUseCase> {
  UpdateQuestionAttemptUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateQuestionAttemptUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateQuestionAttemptUseCaseHash();

  @$internal
  @override
  $FutureProviderElement<UpdateQuestionAttemptUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UpdateQuestionAttemptUseCase> create(Ref ref) {
    return updateQuestionAttemptUseCase(ref);
  }
}

String _$updateQuestionAttemptUseCaseHash() =>
    r'0f1c6f4e599f609119887cf67f8e21de14bcc7a2';

@ProviderFor(updateQuestionTimeUseCase)
final updateQuestionTimeUseCaseProvider = UpdateQuestionTimeUseCaseProvider._();

final class UpdateQuestionTimeUseCaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<UpdateQuestionTimeUseCase>,
          UpdateQuestionTimeUseCase,
          FutureOr<UpdateQuestionTimeUseCase>
        >
    with
        $FutureModifier<UpdateQuestionTimeUseCase>,
        $FutureProvider<UpdateQuestionTimeUseCase> {
  UpdateQuestionTimeUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateQuestionTimeUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateQuestionTimeUseCaseHash();

  @$internal
  @override
  $FutureProviderElement<UpdateQuestionTimeUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UpdateQuestionTimeUseCase> create(Ref ref) {
    return updateQuestionTimeUseCase(ref);
  }
}

String _$updateQuestionTimeUseCaseHash() =>
    r'f30a7194f7bba35a6dc56a1da6b20703b636e760';

@ProviderFor(flagQuestionUseCase)
final flagQuestionUseCaseProvider = FlagQuestionUseCaseProvider._();

final class FlagQuestionUseCaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<FlagQuestionUseCase>,
          FlagQuestionUseCase,
          FutureOr<FlagQuestionUseCase>
        >
    with
        $FutureModifier<FlagQuestionUseCase>,
        $FutureProvider<FlagQuestionUseCase> {
  FlagQuestionUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flagQuestionUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flagQuestionUseCaseHash();

  @$internal
  @override
  $FutureProviderElement<FlagQuestionUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FlagQuestionUseCase> create(Ref ref) {
    return flagQuestionUseCase(ref);
  }
}

String _$flagQuestionUseCaseHash() =>
    r'fd105c00edfcfaa34b12219c41e50abb789021ea';

@ProviderFor(submitSessionUseCase)
final submitSessionUseCaseProvider = SubmitSessionUseCaseProvider._();

final class SubmitSessionUseCaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<SubmitSessionUseCase>,
          SubmitSessionUseCase,
          FutureOr<SubmitSessionUseCase>
        >
    with
        $FutureModifier<SubmitSessionUseCase>,
        $FutureProvider<SubmitSessionUseCase> {
  SubmitSessionUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'submitSessionUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$submitSessionUseCaseHash();

  @$internal
  @override
  $FutureProviderElement<SubmitSessionUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SubmitSessionUseCase> create(Ref ref) {
    return submitSessionUseCase(ref);
  }
}

String _$submitSessionUseCaseHash() =>
    r'2f318cfe2f24354893410c7227e0934658af1b82';

@ProviderFor(handleTimedOutQuestionUseCase)
final handleTimedOutQuestionUseCaseProvider =
    HandleTimedOutQuestionUseCaseProvider._();

final class HandleTimedOutQuestionUseCaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<HandleTimedOutQuestionUseCase>,
          HandleTimedOutQuestionUseCase,
          FutureOr<HandleTimedOutQuestionUseCase>
        >
    with
        $FutureModifier<HandleTimedOutQuestionUseCase>,
        $FutureProvider<HandleTimedOutQuestionUseCase> {
  HandleTimedOutQuestionUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'handleTimedOutQuestionUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$handleTimedOutQuestionUseCaseHash();

  @$internal
  @override
  $FutureProviderElement<HandleTimedOutQuestionUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HandleTimedOutQuestionUseCase> create(Ref ref) {
    return handleTimedOutQuestionUseCase(ref);
  }
}

String _$handleTimedOutQuestionUseCaseHash() =>
    r'a659fb3de19186662c615655ad94461c43b5f5b1';

@ProviderFor(markSessionAbandonedUseCase)
final markSessionAbandonedUseCaseProvider =
    MarkSessionAbandonedUseCaseProvider._();

final class MarkSessionAbandonedUseCaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<MarkSessionAbandonedUseCase>,
          MarkSessionAbandonedUseCase,
          FutureOr<MarkSessionAbandonedUseCase>
        >
    with
        $FutureModifier<MarkSessionAbandonedUseCase>,
        $FutureProvider<MarkSessionAbandonedUseCase> {
  MarkSessionAbandonedUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'markSessionAbandonedUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$markSessionAbandonedUseCaseHash();

  @$internal
  @override
  $FutureProviderElement<MarkSessionAbandonedUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MarkSessionAbandonedUseCase> create(Ref ref) {
    return markSessionAbandonedUseCase(ref);
  }
}

String _$markSessionAbandonedUseCaseHash() =>
    r'ac605d5ed6f3efa78c936d3c4b1734740d57986d';

@ProviderFor(sessionHistoryRepository)
final sessionHistoryRepositoryProvider = SessionHistoryRepositoryProvider._();

final class SessionHistoryRepositoryProvider
    extends
        $FunctionalProvider<
          SessionHistoryRepository,
          SessionHistoryRepository,
          SessionHistoryRepository
        >
    with $Provider<SessionHistoryRepository> {
  SessionHistoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionHistoryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionHistoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<SessionHistoryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SessionHistoryRepository create(Ref ref) {
    return sessionHistoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionHistoryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionHistoryRepository>(value),
    );
  }
}

String _$sessionHistoryRepositoryHash() =>
    r'2b37f681f3650fe03a725359b9014149d0f51b28';

@ProviderFor(getSessionResultUseCase)
final getSessionResultUseCaseProvider = GetSessionResultUseCaseProvider._();

final class GetSessionResultUseCaseProvider
    extends
        $FunctionalProvider<
          GetSessionResultUseCase,
          GetSessionResultUseCase,
          GetSessionResultUseCase
        >
    with $Provider<GetSessionResultUseCase> {
  GetSessionResultUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getSessionResultUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getSessionResultUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetSessionResultUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetSessionResultUseCase create(Ref ref) {
    return getSessionResultUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetSessionResultUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetSessionResultUseCase>(value),
    );
  }
}

String _$getSessionResultUseCaseHash() =>
    r'523e109b94793bbe2a853d52248a9c7cb6eaf7c8';

@ProviderFor(getSessionListUseCase)
final getSessionListUseCaseProvider = GetSessionListUseCaseProvider._();

final class GetSessionListUseCaseProvider
    extends
        $FunctionalProvider<
          GetSessionListUseCase,
          GetSessionListUseCase,
          GetSessionListUseCase
        >
    with $Provider<GetSessionListUseCase> {
  GetSessionListUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getSessionListUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getSessionListUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetSessionListUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetSessionListUseCase create(Ref ref) {
    return getSessionListUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetSessionListUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetSessionListUseCase>(value),
    );
  }
}

String _$getSessionListUseCaseHash() =>
    r'948916b9fbf5d58432b3152c97fdc01747c1a31c';

@ProviderFor(getDailyProgressUseCase)
final getDailyProgressUseCaseProvider = GetDailyProgressUseCaseProvider._();

final class GetDailyProgressUseCaseProvider
    extends
        $FunctionalProvider<
          GetDailyProgressUseCase,
          GetDailyProgressUseCase,
          GetDailyProgressUseCase
        >
    with $Provider<GetDailyProgressUseCase> {
  GetDailyProgressUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getDailyProgressUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getDailyProgressUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetDailyProgressUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetDailyProgressUseCase create(Ref ref) {
    return getDailyProgressUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetDailyProgressUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetDailyProgressUseCase>(value),
    );
  }
}

String _$getDailyProgressUseCaseHash() =>
    r'578f6c9e4742c0941c22b9851111e85322a01c4c';

@ProviderFor(sessionResult)
final sessionResultProvider = SessionResultFamily._();

final class SessionResultProvider
    extends
        $FunctionalProvider<
          AsyncValue<SessionResult>,
          SessionResult,
          FutureOr<SessionResult>
        >
    with $FutureModifier<SessionResult>, $FutureProvider<SessionResult> {
  SessionResultProvider._({
    required SessionResultFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sessionResultProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionResultHash();

  @override
  String toString() {
    return r'sessionResultProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<SessionResult> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SessionResult> create(Ref ref) {
    final argument = this.argument as String;
    return sessionResult(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionResultProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionResultHash() => r'0f4c6aef370e03c55e9b2e15b52a0c6f91a9cf7e';

final class SessionResultFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<SessionResult>, String> {
  SessionResultFamily._()
    : super(
        retry: null,
        name: r'sessionResultProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SessionResultProvider call(String sessionId) =>
      SessionResultProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'sessionResultProvider';
}

@ProviderFor(sessionSummaries)
final sessionSummariesProvider = SessionSummariesFamily._();

final class SessionSummariesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SessionSummary>>,
          List<SessionSummary>,
          FutureOr<List<SessionSummary>>
        >
    with
        $FutureModifier<List<SessionSummary>>,
        $FutureProvider<List<SessionSummary>> {
  SessionSummariesProvider._({
    required SessionSummariesFamily super.from,
    required ({String? subject, String? mode}) super.argument,
  }) : super(
         retry: null,
         name: r'sessionSummariesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionSummariesHash();

  @override
  String toString() {
    return r'sessionSummariesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<SessionSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SessionSummary>> create(Ref ref) {
    final argument = this.argument as ({String? subject, String? mode});
    return sessionSummaries(
      ref,
      subject: argument.subject,
      mode: argument.mode,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SessionSummariesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionSummariesHash() => r'5e836e5bf1bb26ee1e59bdc2cb0d69999db5c231';

final class SessionSummariesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<SessionSummary>>,
          ({String? subject, String? mode})
        > {
  SessionSummariesFamily._()
    : super(
        retry: null,
        name: r'sessionSummariesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SessionSummariesProvider call({String? subject, String? mode}) =>
      SessionSummariesProvider._(
        argument: (subject: subject, mode: mode),
        from: this,
      );

  @override
  String toString() => r'sessionSummariesProvider';
}

@ProviderFor(dailyProgressCount)
final dailyProgressCountProvider = DailyProgressCountProvider._();

final class DailyProgressCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  DailyProgressCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyProgressCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyProgressCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return dailyProgressCount(ref);
  }
}

String _$dailyProgressCountHash() =>
    r'fd72fd3f848140cf0273ad37e8a6d04eb5a57d73';

@ProviderFor(revisionRepository)
final revisionRepositoryProvider = RevisionRepositoryProvider._();

final class RevisionRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<RevisionRepository>,
          RevisionRepository,
          FutureOr<RevisionRepository>
        >
    with
        $FutureModifier<RevisionRepository>,
        $FutureProvider<RevisionRepository> {
  RevisionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'revisionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$revisionRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<RevisionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RevisionRepository> create(Ref ref) {
    return revisionRepository(ref);
  }
}

String _$revisionRepositoryHash() =>
    r'bba595dacfed42f553c67f0e393dac6f63262a4f';

@ProviderFor(getRevisionQueueUseCase)
final getRevisionQueueUseCaseProvider = GetRevisionQueueUseCaseProvider._();

final class GetRevisionQueueUseCaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<GetRevisionQueueUseCase>,
          GetRevisionQueueUseCase,
          FutureOr<GetRevisionQueueUseCase>
        >
    with
        $FutureModifier<GetRevisionQueueUseCase>,
        $FutureProvider<GetRevisionQueueUseCase> {
  GetRevisionQueueUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getRevisionQueueUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getRevisionQueueUseCaseHash();

  @$internal
  @override
  $FutureProviderElement<GetRevisionQueueUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GetRevisionQueueUseCase> create(Ref ref) {
    return getRevisionQueueUseCase(ref);
  }
}

String _$getRevisionQueueUseCaseHash() =>
    r'c43b153e49e61fa3e57a5180b9ab6129032d2e55';

@ProviderFor(updateRevisionQueueProgressUseCase)
final updateRevisionQueueProgressUseCaseProvider =
    UpdateRevisionQueueProgressUseCaseProvider._();

final class UpdateRevisionQueueProgressUseCaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<UpdateRevisionQueueProgressUseCase>,
          UpdateRevisionQueueProgressUseCase,
          FutureOr<UpdateRevisionQueueProgressUseCase>
        >
    with
        $FutureModifier<UpdateRevisionQueueProgressUseCase>,
        $FutureProvider<UpdateRevisionQueueProgressUseCase> {
  UpdateRevisionQueueProgressUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateRevisionQueueProgressUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$updateRevisionQueueProgressUseCaseHash();

  @$internal
  @override
  $FutureProviderElement<UpdateRevisionQueueProgressUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UpdateRevisionQueueProgressUseCase> create(Ref ref) {
    return updateRevisionQueueProgressUseCase(ref);
  }
}

String _$updateRevisionQueueProgressUseCaseHash() =>
    r'fabd972d5bdb45e665db95032ecf0bf4465ed060';

@ProviderFor(bookmarksRepository)
final bookmarksRepositoryProvider = BookmarksRepositoryProvider._();

final class BookmarksRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<BookmarksRepository>,
          BookmarksRepository,
          FutureOr<BookmarksRepository>
        >
    with
        $FutureModifier<BookmarksRepository>,
        $FutureProvider<BookmarksRepository> {
  BookmarksRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookmarksRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookmarksRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<BookmarksRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BookmarksRepository> create(Ref ref) {
    return bookmarksRepository(ref);
  }
}

String _$bookmarksRepositoryHash() =>
    r'25201f681e57a194a59b488c85d47edfeb9121f8';

@ProviderFor(getBookmarksUseCase)
final getBookmarksUseCaseProvider = GetBookmarksUseCaseProvider._();

final class GetBookmarksUseCaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<GetBookmarksUseCase>,
          GetBookmarksUseCase,
          FutureOr<GetBookmarksUseCase>
        >
    with
        $FutureModifier<GetBookmarksUseCase>,
        $FutureProvider<GetBookmarksUseCase> {
  GetBookmarksUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getBookmarksUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getBookmarksUseCaseHash();

  @$internal
  @override
  $FutureProviderElement<GetBookmarksUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GetBookmarksUseCase> create(Ref ref) {
    return getBookmarksUseCase(ref);
  }
}

String _$getBookmarksUseCaseHash() =>
    r'd9d5f3005699e0a6463f6ba15b2934fc080c0b7f';

@ProviderFor(addBookmarkUseCase)
final addBookmarkUseCaseProvider = AddBookmarkUseCaseProvider._();

final class AddBookmarkUseCaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<AddBookmarkUseCase>,
          AddBookmarkUseCase,
          FutureOr<AddBookmarkUseCase>
        >
    with
        $FutureModifier<AddBookmarkUseCase>,
        $FutureProvider<AddBookmarkUseCase> {
  AddBookmarkUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addBookmarkUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addBookmarkUseCaseHash();

  @$internal
  @override
  $FutureProviderElement<AddBookmarkUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AddBookmarkUseCase> create(Ref ref) {
    return addBookmarkUseCase(ref);
  }
}

String _$addBookmarkUseCaseHash() =>
    r'71747ff7a1bb03b71c7d6cc2da7014b2ffbd80e4';

@ProviderFor(removeBookmarkUseCase)
final removeBookmarkUseCaseProvider = RemoveBookmarkUseCaseProvider._();

final class RemoveBookmarkUseCaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<RemoveBookmarkUseCase>,
          RemoveBookmarkUseCase,
          FutureOr<RemoveBookmarkUseCase>
        >
    with
        $FutureModifier<RemoveBookmarkUseCase>,
        $FutureProvider<RemoveBookmarkUseCase> {
  RemoveBookmarkUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'removeBookmarkUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$removeBookmarkUseCaseHash();

  @$internal
  @override
  $FutureProviderElement<RemoveBookmarkUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RemoveBookmarkUseCase> create(Ref ref) {
    return removeBookmarkUseCase(ref);
  }
}

String _$removeBookmarkUseCaseHash() =>
    r'032a8a9463de451d234e8526449a651d203999a7';

@ProviderFor(getHomeStateUseCase)
final getHomeStateUseCaseProvider = GetHomeStateUseCaseProvider._();

final class GetHomeStateUseCaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<GetHomeStateUseCase>,
          GetHomeStateUseCase,
          FutureOr<GetHomeStateUseCase>
        >
    with
        $FutureModifier<GetHomeStateUseCase>,
        $FutureProvider<GetHomeStateUseCase> {
  GetHomeStateUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getHomeStateUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getHomeStateUseCaseHash();

  @$internal
  @override
  $FutureProviderElement<GetHomeStateUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GetHomeStateUseCase> create(Ref ref) {
    return getHomeStateUseCase(ref);
  }
}

String _$getHomeStateUseCaseHash() =>
    r'b771ea3103a2f4ff1e0a23bbdf5d41d9b195631c';

@ProviderFor(updateStreakUseCase)
final updateStreakUseCaseProvider = UpdateStreakUseCaseProvider._();

final class UpdateStreakUseCaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<UpdateStreakUseCase>,
          UpdateStreakUseCase,
          FutureOr<UpdateStreakUseCase>
        >
    with
        $FutureModifier<UpdateStreakUseCase>,
        $FutureProvider<UpdateStreakUseCase> {
  UpdateStreakUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateStreakUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateStreakUseCaseHash();

  @$internal
  @override
  $FutureProviderElement<UpdateStreakUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UpdateStreakUseCase> create(Ref ref) {
    return updateStreakUseCase(ref);
  }
}

String _$updateStreakUseCaseHash() =>
    r'786c69396249a99844195d86a41af97464583c14';

@ProviderFor(revisionQueueItems)
final revisionQueueItemsProvider = RevisionQueueItemsProvider._();

final class RevisionQueueItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RevisionQueueItem>>,
          List<RevisionQueueItem>,
          FutureOr<List<RevisionQueueItem>>
        >
    with
        $FutureModifier<List<RevisionQueueItem>>,
        $FutureProvider<List<RevisionQueueItem>> {
  RevisionQueueItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'revisionQueueItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$revisionQueueItemsHash();

  @$internal
  @override
  $FutureProviderElement<List<RevisionQueueItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RevisionQueueItem>> create(Ref ref) {
    return revisionQueueItems(ref);
  }
}

String _$revisionQueueItemsHash() =>
    r'87772c98ba3a80de5a596826389a469084d55929';

@ProviderFor(bookmarksList)
final bookmarksListProvider = BookmarksListProvider._();

final class BookmarksListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BookmarkItem>>,
          List<BookmarkItem>,
          FutureOr<List<BookmarkItem>>
        >
    with
        $FutureModifier<List<BookmarkItem>>,
        $FutureProvider<List<BookmarkItem>> {
  BookmarksListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookmarksListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookmarksListHash();

  @$internal
  @override
  $FutureProviderElement<List<BookmarkItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BookmarkItem>> create(Ref ref) {
    return bookmarksList(ref);
  }
}

String _$bookmarksListHash() => r'03c1253d52c270152835d768921400b5aa9adc17';

@ProviderFor(homeState)
final homeStateProvider = HomeStateProvider._();

final class HomeStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<HomeState>,
          HomeState,
          FutureOr<HomeState>
        >
    with $FutureModifier<HomeState>, $FutureProvider<HomeState> {
  HomeStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeStateHash();

  @$internal
  @override
  $FutureProviderElement<HomeState> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<HomeState> create(Ref ref) {
    return homeState(ref);
  }
}

String _$homeStateHash() => r'ccb5a4770d9cf916e580701e63d06e5446326c9d';

@ProviderFor(totalQuestionCount)
final totalQuestionCountProvider = TotalQuestionCountProvider._();

final class TotalQuestionCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  TotalQuestionCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalQuestionCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalQuestionCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return totalQuestionCount(ref);
  }
}

String _$totalQuestionCountHash() =>
    r'94994b6afd1b2423b3707fd5f1769f6889262d14';
