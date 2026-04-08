// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_filters_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HistoryFilterState)
final historyFilterStateProvider = HistoryFilterStateProvider._();

final class HistoryFilterStateProvider
    extends $NotifierProvider<HistoryFilterState, HistoryFilters> {
  HistoryFilterStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyFilterStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyFilterStateHash();

  @$internal
  @override
  HistoryFilterState create() => HistoryFilterState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HistoryFilters value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HistoryFilters>(value),
    );
  }
}

String _$historyFilterStateHash() =>
    r'72ddc2c26b2452bea7e266908849e466462850b5';

abstract class _$HistoryFilterState extends $Notifier<HistoryFilters> {
  HistoryFilters build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<HistoryFilters, HistoryFilters>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HistoryFilters, HistoryFilters>,
              HistoryFilters,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
