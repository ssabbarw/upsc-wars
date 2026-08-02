// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_activation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HomeActivation)
final homeActivationProvider = HomeActivationProvider._();

final class HomeActivationProvider
    extends $AsyncNotifierProvider<HomeActivation, HomeActivationState> {
  HomeActivationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeActivationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeActivationHash();

  @$internal
  @override
  HomeActivation create() => HomeActivation();
}

String _$homeActivationHash() => r'7bca4971cf95464774aeacd937627efbdf77ebca';

abstract class _$HomeActivation extends $AsyncNotifier<HomeActivationState> {
  FutureOr<HomeActivationState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<HomeActivationState>, HomeActivationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<HomeActivationState>, HomeActivationState>,
              AsyncValue<HomeActivationState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
