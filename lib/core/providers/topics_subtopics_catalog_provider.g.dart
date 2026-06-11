// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topics_subtopics_catalog_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads [TopicsSubtopicsCatalog] once from bundled JSON.

@ProviderFor(topicsSubtopicsCatalog)
final topicsSubtopicsCatalogProvider = TopicsSubtopicsCatalogProvider._();

/// Loads [TopicsSubtopicsCatalog] once from bundled JSON.

final class TopicsSubtopicsCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<TopicsSubtopicsCatalog>,
          TopicsSubtopicsCatalog,
          FutureOr<TopicsSubtopicsCatalog>
        >
    with
        $FutureModifier<TopicsSubtopicsCatalog>,
        $FutureProvider<TopicsSubtopicsCatalog> {
  /// Loads [TopicsSubtopicsCatalog] once from bundled JSON.
  TopicsSubtopicsCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'topicsSubtopicsCatalogProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$topicsSubtopicsCatalogHash();

  @$internal
  @override
  $FutureProviderElement<TopicsSubtopicsCatalog> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TopicsSubtopicsCatalog> create(Ref ref) {
    return topicsSubtopicsCatalog(ref);
  }
}

String _$topicsSubtopicsCatalogHash() =>
    r'a4cfc628684e38d2ed3c70947be0e18f465d1225';
