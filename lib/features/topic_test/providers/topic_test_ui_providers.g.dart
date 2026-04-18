// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic_test_ui_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TopicTestSelectedSubjectSlug)
final topicTestSelectedSubjectSlugProvider =
    TopicTestSelectedSubjectSlugProvider._();

final class TopicTestSelectedSubjectSlugProvider
    extends $NotifierProvider<TopicTestSelectedSubjectSlug, String> {
  TopicTestSelectedSubjectSlugProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'topicTestSelectedSubjectSlugProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$topicTestSelectedSubjectSlugHash();

  @$internal
  @override
  TopicTestSelectedSubjectSlug create() => TopicTestSelectedSubjectSlug();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$topicTestSelectedSubjectSlugHash() =>
    r'cb81c5e26b28564efbbc992f760af057a0f91f2c';

abstract class _$TopicTestSelectedSubjectSlug extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(TopicTestSearchQuery)
final topicTestSearchQueryProvider = TopicTestSearchQueryProvider._();

final class TopicTestSearchQueryProvider
    extends $NotifierProvider<TopicTestSearchQuery, String> {
  TopicTestSearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'topicTestSearchQueryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$topicTestSearchQueryHash();

  @$internal
  @override
  TopicTestSearchQuery create() => TopicTestSearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$topicTestSearchQueryHash() =>
    r'87873e520de0d816a57dca58c04039b41e67d041';

abstract class _$TopicTestSearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(topicTestDisplayedTopics)
final topicTestDisplayedTopicsProvider = TopicTestDisplayedTopicsProvider._();

final class TopicTestDisplayedTopicsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TopicInfo>>,
          List<TopicInfo>,
          FutureOr<List<TopicInfo>>
        >
    with $FutureModifier<List<TopicInfo>>, $FutureProvider<List<TopicInfo>> {
  TopicTestDisplayedTopicsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'topicTestDisplayedTopicsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$topicTestDisplayedTopicsHash();

  @$internal
  @override
  $FutureProviderElement<List<TopicInfo>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TopicInfo>> create(Ref ref) {
    return topicTestDisplayedTopics(ref);
  }
}

String _$topicTestDisplayedTopicsHash() =>
    r'f70673f77ef2361e0759649f8112d03e13c149cb';
