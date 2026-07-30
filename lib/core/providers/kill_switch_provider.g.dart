// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kill_switch_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(killSwitch)
final killSwitchProvider = KillSwitchProvider._();

final class KillSwitchProvider
    extends
        $FunctionalProvider<
          AsyncValue<KillSwitchSnapshot>,
          KillSwitchSnapshot,
          FutureOr<KillSwitchSnapshot>
        >
    with
        $FutureModifier<KillSwitchSnapshot>,
        $FutureProvider<KillSwitchSnapshot> {
  KillSwitchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'killSwitchProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$killSwitchHash();

  @$internal
  @override
  $FutureProviderElement<KillSwitchSnapshot> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<KillSwitchSnapshot> create(Ref ref) {
    return killSwitch(ref);
  }
}

String _$killSwitchHash() => r'5c3f0e6dac57d8c6a0898827bed0981ef4dc26e2';

/// Whether the Community tab should be shown (after [killSwitchProvider] fetch).
///
/// Fails open (`true`) while loading or on read errors so the tab stays unless RC
/// explicitly disables it. On web, only [FeatureFlags.communityTab] applies.

@ProviderFor(communityTabRemoteEnabled)
final communityTabRemoteEnabledProvider = CommunityTabRemoteEnabledProvider._();

/// Whether the Community tab should be shown (after [killSwitchProvider] fetch).
///
/// Fails open (`true`) while loading or on read errors so the tab stays unless RC
/// explicitly disables it. On web, only [FeatureFlags.communityTab] applies.

final class CommunityTabRemoteEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether the Community tab should be shown (after [killSwitchProvider] fetch).
  ///
  /// Fails open (`true`) while loading or on read errors so the tab stays unless RC
  /// explicitly disables it. On web, only [FeatureFlags.communityTab] applies.
  CommunityTabRemoteEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'communityTabRemoteEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$communityTabRemoteEnabledHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return communityTabRemoteEnabled(ref);
  }
}

String _$communityTabRemoteEnabledHash() =>
    r'ed6ce0ddcb75b90a24cf3013c80fd3c4ce8b8b21';

/// Whether the Daily Current Affairs home entry should be shown.
///
/// Fails closed (`false`) while loading or on read errors.

@ProviderFor(dailyCaRemoteEnabled)
final dailyCaRemoteEnabledProvider = DailyCaRemoteEnabledProvider._();

/// Whether the Daily Current Affairs home entry should be shown.
///
/// Fails closed (`false`) while loading or on read errors.

final class DailyCaRemoteEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether the Daily Current Affairs home entry should be shown.
  ///
  /// Fails closed (`false`) while loading or on read errors.
  DailyCaRemoteEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyCaRemoteEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyCaRemoteEnabledHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return dailyCaRemoteEnabled(ref);
  }
}

String _$dailyCaRemoteEnabledHash() =>
    r'656cc2f8b3d20f324a31a3181b605c5fcac9caef';

/// Fact or Bluff countdown length from Remote Config (seconds).
///
/// Defaults to 10. Clamped to 3–60. Waits for [killSwitchProvider] so RC
/// defaults / fetch have run on mobile.

@ProviderFor(factOrBluffSecondsRemote)
final factOrBluffSecondsRemoteProvider = FactOrBluffSecondsRemoteProvider._();

/// Fact or Bluff countdown length from Remote Config (seconds).
///
/// Defaults to 10. Clamped to 3–60. Waits for [killSwitchProvider] so RC
/// defaults / fetch have run on mobile.

final class FactOrBluffSecondsRemoteProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Fact or Bluff countdown length from Remote Config (seconds).
  ///
  /// Defaults to 10. Clamped to 3–60. Waits for [killSwitchProvider] so RC
  /// defaults / fetch have run on mobile.
  FactOrBluffSecondsRemoteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'factOrBluffSecondsRemoteProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$factOrBluffSecondsRemoteHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return factOrBluffSecondsRemote(ref);
  }
}

String _$factOrBluffSecondsRemoteHash() =>
    r'69cff7bde3da51daadeeb847c3e2c46f1cf86e99';
