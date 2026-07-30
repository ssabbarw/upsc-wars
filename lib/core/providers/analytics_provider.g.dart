// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Global [AnalyticsService] wiring [FirebaseAnalyticsSink] and
/// [LocalAnalyticsSink]; event meanings are on each [AnalyticsEvent] subclass.

@ProviderFor(analyticsService)
final analyticsServiceProvider = AnalyticsServiceProvider._();

/// Global [AnalyticsService] wiring [FirebaseAnalyticsSink] and
/// [LocalAnalyticsSink]; event meanings are on each [AnalyticsEvent] subclass.

final class AnalyticsServiceProvider
    extends
        $FunctionalProvider<
          AnalyticsService,
          AnalyticsService,
          AnalyticsService
        >
    with $Provider<AnalyticsService> {
  /// Global [AnalyticsService] wiring [FirebaseAnalyticsSink] and
  /// [LocalAnalyticsSink]; event meanings are on each [AnalyticsEvent] subclass.
  AnalyticsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsServiceHash();

  @$internal
  @override
  $ProviderElement<AnalyticsService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AnalyticsService create(Ref ref) {
    return analyticsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnalyticsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnalyticsService>(value),
    );
  }
}

String _$analyticsServiceHash() => r'9f0be590732f4d32f7ff69bf803e53599f1fb730';
