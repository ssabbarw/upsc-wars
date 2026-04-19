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

String _$killSwitchHash() => r'5d423d501caf66254e1481b2cb5dd90064b6ab8d';
