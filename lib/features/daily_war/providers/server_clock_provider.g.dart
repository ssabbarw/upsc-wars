// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_clock_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Offset in ms: `serverNow ≈ DateTime.now().millisecondsSinceEpoch + offset`.
///
/// Backed by Firebase RTDB `.info/serverTimeOffset`. Falls back to `0` (device
/// clock) when unavailable (web without RTDB, offline cold start).

@ProviderFor(serverTimeOffsetMs)
final serverTimeOffsetMsProvider = ServerTimeOffsetMsProvider._();

/// Offset in ms: `serverNow ≈ DateTime.now().millisecondsSinceEpoch + offset`.
///
/// Backed by Firebase RTDB `.info/serverTimeOffset`. Falls back to `0` (device
/// clock) when unavailable (web without RTDB, offline cold start).

final class ServerTimeOffsetMsProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Offset in ms: `serverNow ≈ DateTime.now().millisecondsSinceEpoch + offset`.
  ///
  /// Backed by Firebase RTDB `.info/serverTimeOffset`. Falls back to `0` (device
  /// clock) when unavailable (web without RTDB, offline cold start).
  ServerTimeOffsetMsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverTimeOffsetMsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverTimeOffsetMsHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return serverTimeOffsetMs(ref);
  }
}

String _$serverTimeOffsetMsHash() =>
    r'10498d0ad042adaeb56c2acc399251f96734e442';

/// Corrected "now" as UTC [DateTime], refreshing when the offset stream updates.

@ProviderFor(serverNowUtc)
final serverNowUtcProvider = ServerNowUtcProvider._();

/// Corrected "now" as UTC [DateTime], refreshing when the offset stream updates.

final class ServerNowUtcProvider
    extends $FunctionalProvider<DateTime, DateTime, DateTime>
    with $Provider<DateTime> {
  /// Corrected "now" as UTC [DateTime], refreshing when the offset stream updates.
  ServerNowUtcProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverNowUtcProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverNowUtcHash();

  @$internal
  @override
  $ProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DateTime create(Ref ref) {
    return serverNowUtc(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$serverNowUtcHash() => r'5861bdef24ddb02f1a270496e2d7ddb74eb7c2f7';
