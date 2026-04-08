// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_db_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(questionDb)
final questionDbProvider = QuestionDbProvider._();

final class QuestionDbProvider
    extends
        $FunctionalProvider<
          AsyncValue<QuestionDb>,
          QuestionDb,
          FutureOr<QuestionDb>
        >
    with $FutureModifier<QuestionDb>, $FutureProvider<QuestionDb> {
  QuestionDbProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'questionDbProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$questionDbHash();

  @$internal
  @override
  $FutureProviderElement<QuestionDb> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<QuestionDb> create(Ref ref) {
    return questionDb(ref);
  }
}

String _$questionDbHash() => r'cac40d021a440d2ccc5f46e29a05c4549cd3e9a1';
