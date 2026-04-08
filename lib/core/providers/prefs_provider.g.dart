// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prefs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<SharedPreferences>,
          SharedPreferences,
          FutureOr<SharedPreferences>
        >
    with
        $FutureModifier<SharedPreferences>,
        $FutureProvider<SharedPreferences> {
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $FutureProviderElement<SharedPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SharedPreferences> create(Ref ref) {
    return sharedPreferences(ref);
  }
}

String _$sharedPreferencesHash() => r'969a9a58addd687a4c1432a3858b65fccd47c4a4';

@ProviderFor(prefsService)
final prefsServiceProvider = PrefsServiceProvider._();

final class PrefsServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<PrefsService>,
          PrefsService,
          FutureOr<PrefsService>
        >
    with $FutureModifier<PrefsService>, $FutureProvider<PrefsService> {
  PrefsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'prefsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$prefsServiceHash();

  @$internal
  @override
  $FutureProviderElement<PrefsService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PrefsService> create(Ref ref) {
    return prefsService(ref);
  }
}

String _$prefsServiceHash() => r'3f55327fee9dfa9dfafa608716cae328ffbbde41';
