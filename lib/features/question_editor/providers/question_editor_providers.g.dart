// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_editor_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(questionEditorRepository)
final questionEditorRepositoryProvider = QuestionEditorRepositoryProvider._();

final class QuestionEditorRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<QuestionEditorRepository>,
          QuestionEditorRepository,
          FutureOr<QuestionEditorRepository>
        >
    with
        $FutureModifier<QuestionEditorRepository>,
        $FutureProvider<QuestionEditorRepository> {
  QuestionEditorRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'questionEditorRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$questionEditorRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<QuestionEditorRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<QuestionEditorRepository> create(Ref ref) {
    return questionEditorRepository(ref);
  }
}

String _$questionEditorRepositoryHash() =>
    r'question_editor_repository_provider_hash_v1';

@ProviderFor(questionCorrectionsSyncService)
final questionCorrectionsSyncServiceProvider =
    QuestionCorrectionsSyncServiceProvider._();

final class QuestionCorrectionsSyncServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<QuestionCorrectionsSyncService>,
          QuestionCorrectionsSyncService,
          FutureOr<QuestionCorrectionsSyncService>
        >
    with
        $FutureModifier<QuestionCorrectionsSyncService>,
        $FutureProvider<QuestionCorrectionsSyncService> {
  QuestionCorrectionsSyncServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'questionCorrectionsSyncServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$questionCorrectionsSyncServiceHash();

  @$internal
  @override
  $FutureProviderElement<QuestionCorrectionsSyncService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<QuestionCorrectionsSyncService> create(Ref ref) {
    return questionCorrectionsSyncService(ref);
  }
}

String _$questionCorrectionsSyncServiceHash() =>
    r'question_corrections_sync_service_provider_hash_v1';
