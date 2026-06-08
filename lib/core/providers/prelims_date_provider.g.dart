// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prelims_date_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(prelimsDate)
final prelimsDateProvider = PrelimsDateProvider._();

final class PrelimsDateProvider
    extends
        $FunctionalProvider<AsyncValue<DateTime>, DateTime, FutureOr<DateTime>>
    with $FutureModifier<DateTime>, $FutureProvider<DateTime> {
  PrelimsDateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'prelimsDateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$prelimsDateHash();

  @$internal
  @override
  $FutureProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<DateTime> create(Ref ref) {
    return prelimsDate(ref);
  }
}

String _$prelimsDateHash() => r'be170009b7181eb3eac19bbab9dffa44a6862285';
