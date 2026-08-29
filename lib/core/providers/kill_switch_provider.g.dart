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

String _$killSwitchHash() => r'f09ad40962bfe18e3234d58a8c2bbf46071e783b';

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

/// Whether Daily War is available for the **signed-in user**.
///
/// Requires [dailyWarEnabledRemoteConfigKey]. If
/// [dailyWarAdminsOnlyRemoteConfigKey] is true, only super-users pass.
/// Fails closed (`false`) while loading or on read errors.

@ProviderFor(dailyWarRemoteEnabled)
final dailyWarRemoteEnabledProvider = DailyWarRemoteEnabledProvider._();

/// Whether Daily War is available for the **signed-in user**.
///
/// Requires [dailyWarEnabledRemoteConfigKey]. If
/// [dailyWarAdminsOnlyRemoteConfigKey] is true, only super-users pass.
/// Fails closed (`false`) while loading or on read errors.

final class DailyWarRemoteEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether Daily War is available for the **signed-in user**.
  ///
  /// Requires [dailyWarEnabledRemoteConfigKey]. If
  /// [dailyWarAdminsOnlyRemoteConfigKey] is true, only super-users pass.
  /// Fails closed (`false`) while loading or on read errors.
  DailyWarRemoteEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyWarRemoteEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyWarRemoteEnabledHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return dailyWarRemoteEnabled(ref);
  }
}

String _$dailyWarRemoteEnabledHash() =>
    r'7f708e844592c1459d4ee853dc68d15fa6cd4f96';

/// Raw RC: Daily War limited to admin accounts (ignores who is signed in).

@ProviderFor(dailyWarAdminsOnlyRemote)
final dailyWarAdminsOnlyRemoteProvider = DailyWarAdminsOnlyRemoteProvider._();

/// Raw RC: Daily War limited to admin accounts (ignores who is signed in).

final class DailyWarAdminsOnlyRemoteProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Raw RC: Daily War limited to admin accounts (ignores who is signed in).
  DailyWarAdminsOnlyRemoteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyWarAdminsOnlyRemoteProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyWarAdminsOnlyRemoteHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return dailyWarAdminsOnlyRemote(ref);
  }
}

String _$dailyWarAdminsOnlyRemoteHash() =>
    r'94e35951f8b5e1013d5d66bdea0f5e721aeea5b6';

/// Whether lobby / participant count numbers should be shown on War surfaces.
///
/// Fails open (`true`) so counts stay visible unless RC explicitly disables them.

@ProviderFor(dailyWarLobbyCountRemoteEnabled)
final dailyWarLobbyCountRemoteEnabledProvider =
    DailyWarLobbyCountRemoteEnabledProvider._();

/// Whether lobby / participant count numbers should be shown on War surfaces.
///
/// Fails open (`true`) so counts stay visible unless RC explicitly disables them.

final class DailyWarLobbyCountRemoteEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether lobby / participant count numbers should be shown on War surfaces.
  ///
  /// Fails open (`true`) so counts stay visible unless RC explicitly disables them.
  DailyWarLobbyCountRemoteEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyWarLobbyCountRemoteEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyWarLobbyCountRemoteEnabledHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return dailyWarLobbyCountRemoteEnabled(ref);
  }
}

String _$dailyWarLobbyCountRemoteEnabledHash() =>
    r'5da6bcf525e46899d32baa76b00d051272750d93';

/// Minimum lobby/participant count before showing the raw number.

@ProviderFor(dailyWarMinVisibleLobbyCountRemote)
final dailyWarMinVisibleLobbyCountRemoteProvider =
    DailyWarMinVisibleLobbyCountRemoteProvider._();

/// Minimum lobby/participant count before showing the raw number.

final class DailyWarMinVisibleLobbyCountRemoteProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Minimum lobby/participant count before showing the raw number.
  DailyWarMinVisibleLobbyCountRemoteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyWarMinVisibleLobbyCountRemoteProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$dailyWarMinVisibleLobbyCountRemoteHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return dailyWarMinVisibleLobbyCountRemote(ref);
  }
}

String _$dailyWarMinVisibleLobbyCountRemoteHash() =>
    r'0e5565bb50e7a2f4aeaed2cd2b9015ac486df170';

/// How often clients poll RTDB live counts during lobby / live (seconds).
///
/// Defaults to 15. Clamped to 3–60.

@ProviderFor(dailyWarLiveCountPollSecondsRemote)
final dailyWarLiveCountPollSecondsRemoteProvider =
    DailyWarLiveCountPollSecondsRemoteProvider._();

/// How often clients poll RTDB live counts during lobby / live (seconds).
///
/// Defaults to 15. Clamped to 3–60.

final class DailyWarLiveCountPollSecondsRemoteProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// How often clients poll RTDB live counts during lobby / live (seconds).
  ///
  /// Defaults to 15. Clamped to 3–60.
  DailyWarLiveCountPollSecondsRemoteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyWarLiveCountPollSecondsRemoteProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$dailyWarLiveCountPollSecondsRemoteHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return dailyWarLiveCountPollSecondsRemote(ref);
  }
}

String _$dailyWarLiveCountPollSecondsRemoteHash() =>
    r'b27b16069ff788ec83b0c2b3e228e7ae224858ec';

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
