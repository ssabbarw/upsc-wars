// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_page_video_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(homePageVideoPayload)
final homePageVideoPayloadProvider = HomePageVideoPayloadProvider._();

final class HomePageVideoPayloadProvider
    extends
        $FunctionalProvider<
          AsyncValue<HomePageVideoPayload?>,
          HomePageVideoPayload?,
          FutureOr<HomePageVideoPayload?>
        >
    with
        $FutureModifier<HomePageVideoPayload?>,
        $FutureProvider<HomePageVideoPayload?> {
  HomePageVideoPayloadProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homePageVideoPayloadProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homePageVideoPayloadHash();

  @$internal
  @override
  $FutureProviderElement<HomePageVideoPayload?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HomePageVideoPayload?> create(Ref ref) {
    return homePageVideoPayload(ref);
  }
}

String _$homePageVideoPayloadHash() =>
    r'297f928620a63ecd1473f050b2a5d5741ac8334e';

@ProviderFor(homePageVideoVisible)
final homePageVideoVisibleProvider = HomePageVideoVisibleProvider._();

final class HomePageVideoVisibleProvider
    extends
        $FunctionalProvider<
          AsyncValue<HomePageVideoPayload?>,
          HomePageVideoPayload?,
          FutureOr<HomePageVideoPayload?>
        >
    with
        $FutureModifier<HomePageVideoPayload?>,
        $FutureProvider<HomePageVideoPayload?> {
  HomePageVideoVisibleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homePageVideoVisibleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homePageVideoVisibleHash();

  @$internal
  @override
  $FutureProviderElement<HomePageVideoPayload?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HomePageVideoPayload?> create(Ref ref) {
    return homePageVideoVisible(ref);
  }
}

String _$homePageVideoVisibleHash() =>
    r'e19ae460ab1c6972a172e44d3cef6411bad6586e';
