// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trap_descriptions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads the trap descriptions JSON once and keeps it alive.
/// Returns a map of trap-type slug → [TrapDescription].

@ProviderFor(trapDescriptions)
final trapDescriptionsProvider = TrapDescriptionsProvider._();

/// Loads the trap descriptions JSON once and keeps it alive.
/// Returns a map of trap-type slug → [TrapDescription].

final class TrapDescriptionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, TrapDescription>>,
          Map<String, TrapDescription>,
          FutureOr<Map<String, TrapDescription>>
        >
    with
        $FutureModifier<Map<String, TrapDescription>>,
        $FutureProvider<Map<String, TrapDescription>> {
  /// Loads the trap descriptions JSON once and keeps it alive.
  /// Returns a map of trap-type slug → [TrapDescription].
  TrapDescriptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trapDescriptionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trapDescriptionsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, TrapDescription>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, TrapDescription>> create(Ref ref) {
    return trapDescriptions(ref);
  }
}

String _$trapDescriptionsHash() => r'c0e93b7cc973187b0b025ffbffbbbcc4bf78dc86';
