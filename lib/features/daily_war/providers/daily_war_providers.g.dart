// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_war_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dailyWarLocalCache)
final dailyWarLocalCacheProvider = DailyWarLocalCacheProvider._();

final class DailyWarLocalCacheProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailyWarLocalCache>,
          DailyWarLocalCache,
          FutureOr<DailyWarLocalCache>
        >
    with
        $FutureModifier<DailyWarLocalCache>,
        $FutureProvider<DailyWarLocalCache> {
  DailyWarLocalCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyWarLocalCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyWarLocalCacheHash();

  @$internal
  @override
  $FutureProviderElement<DailyWarLocalCache> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DailyWarLocalCache> create(Ref ref) {
    return dailyWarLocalCache(ref);
  }
}

String _$dailyWarLocalCacheHash() =>
    r'9eef82da6fe1f7771f7fb635b9be582d97dbef29';

/// Today's War dateId (IST) using server-corrected clock.

@ProviderFor(dailyWarTodayDateId)
final dailyWarTodayDateIdProvider = DailyWarTodayDateIdProvider._();

/// Today's War dateId (IST) using server-corrected clock.

final class DailyWarTodayDateIdProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Today's War dateId (IST) using server-corrected clock.
  DailyWarTodayDateIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyWarTodayDateIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyWarTodayDateIdHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return dailyWarTodayDateId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$dailyWarTodayDateIdHash() =>
    r'52f0be5e82ac693db9a9d32b5233067549162214';

/// Keys hydrated from Firestore once per app session (no snapshot listeners).

@ProviderFor(DailyWarSessionHydrated)
final dailyWarSessionHydratedProvider = DailyWarSessionHydratedProvider._();

/// Keys hydrated from Firestore once per app session (no snapshot listeners).
final class DailyWarSessionHydratedProvider
    extends $NotifierProvider<DailyWarSessionHydrated, Set<String>> {
  /// Keys hydrated from Firestore once per app session (no snapshot listeners).
  DailyWarSessionHydratedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyWarSessionHydratedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyWarSessionHydratedHash();

  @$internal
  @override
  DailyWarSessionHydrated create() => DailyWarSessionHydrated();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$dailyWarSessionHydratedHash() =>
    r'be96878daf5ae4bd317e31b73d7c1f700ba3a269';

/// Keys hydrated from Firestore once per app session (no snapshot listeners).

abstract class _$DailyWarSessionHydrated extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Today's War public doc — one server read per app open, then local only.

@ProviderFor(DailyWarTodayDoc)
final dailyWarTodayDocProvider = DailyWarTodayDocProvider._();

/// Today's War public doc — one server read per app open, then local only.
final class DailyWarTodayDocProvider
    extends $AsyncNotifierProvider<DailyWarTodayDoc, DailyWarDoc?> {
  /// Today's War public doc — one server read per app open, then local only.
  DailyWarTodayDocProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyWarTodayDocProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyWarTodayDocHash();

  @$internal
  @override
  DailyWarTodayDoc create() => DailyWarTodayDoc();
}

String _$dailyWarTodayDocHash() => r'2c69c218a427a377620aed763af02f8fee6ef5db';

/// Today's War public doc — one server read per app open, then local only.

abstract class _$DailyWarTodayDoc extends $AsyncNotifier<DailyWarDoc?> {
  FutureOr<DailyWarDoc?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DailyWarDoc?>, DailyWarDoc?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DailyWarDoc?>, DailyWarDoc?>,
              AsyncValue<DailyWarDoc?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Signed-in user's submission for today — one server read per app open.

@ProviderFor(DailyWarTodaySubmission)
final dailyWarTodaySubmissionProvider = DailyWarTodaySubmissionProvider._();

/// Signed-in user's submission for today — one server read per app open.
final class DailyWarTodaySubmissionProvider
    extends
        $AsyncNotifierProvider<DailyWarTodaySubmission, DailyWarSubmission?> {
  /// Signed-in user's submission for today — one server read per app open.
  DailyWarTodaySubmissionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyWarTodaySubmissionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyWarTodaySubmissionHash();

  @$internal
  @override
  DailyWarTodaySubmission create() => DailyWarTodaySubmission();
}

String _$dailyWarTodaySubmissionHash() =>
    r'db4593f97518e638ab0481c0c78c47978b698119';

/// Signed-in user's submission for today — one server read per app open.

abstract class _$DailyWarTodaySubmission
    extends $AsyncNotifier<DailyWarSubmission?> {
  FutureOr<DailyWarSubmission?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<DailyWarSubmission?>, DailyWarSubmission?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DailyWarSubmission?>, DailyWarSubmission?>,
              AsyncValue<DailyWarSubmission?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(dailyWarHomeSnapshot)
final dailyWarHomeSnapshotProvider = DailyWarHomeSnapshotProvider._();

final class DailyWarHomeSnapshotProvider
    extends
        $FunctionalProvider<
          DailyWarHomeSnapshot,
          DailyWarHomeSnapshot,
          DailyWarHomeSnapshot
        >
    with $Provider<DailyWarHomeSnapshot> {
  DailyWarHomeSnapshotProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyWarHomeSnapshotProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyWarHomeSnapshotHash();

  @$internal
  @override
  $ProviderElement<DailyWarHomeSnapshot> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DailyWarHomeSnapshot create(Ref ref) {
    return dailyWarHomeSnapshot(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DailyWarHomeSnapshot value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DailyWarHomeSnapshot>(value),
    );
  }
}

String _$dailyWarHomeSnapshotHash() =>
    r'd09c6761bf18c69a4970a02e161bd42d1b8bf905';

@ProviderFor(dailyWarYesterdayDateId)
final dailyWarYesterdayDateIdProvider = DailyWarYesterdayDateIdProvider._();

final class DailyWarYesterdayDateIdProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  DailyWarYesterdayDateIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyWarYesterdayDateIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyWarYesterdayDateIdHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return dailyWarYesterdayDateId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$dailyWarYesterdayDateIdHash() =>
    r'5193e81a815266c28d250d19d692e0ec39e812df';

@ProviderFor(DailyWarYesterdayDoc)
final dailyWarYesterdayDocProvider = DailyWarYesterdayDocProvider._();

final class DailyWarYesterdayDocProvider
    extends $AsyncNotifierProvider<DailyWarYesterdayDoc, DailyWarDoc?> {
  DailyWarYesterdayDocProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyWarYesterdayDocProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyWarYesterdayDocHash();

  @$internal
  @override
  DailyWarYesterdayDoc create() => DailyWarYesterdayDoc();
}

String _$dailyWarYesterdayDocHash() =>
    r'8285f206cce8de32257082b1aefcb89271e63a46';

abstract class _$DailyWarYesterdayDoc extends $AsyncNotifier<DailyWarDoc?> {
  FutureOr<DailyWarDoc?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DailyWarDoc?>, DailyWarDoc?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DailyWarDoc?>, DailyWarDoc?>,
              AsyncValue<DailyWarDoc?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(DailyWarYesterdaySubmission)
final dailyWarYesterdaySubmissionProvider =
    DailyWarYesterdaySubmissionProvider._();

final class DailyWarYesterdaySubmissionProvider
    extends
        $AsyncNotifierProvider<
          DailyWarYesterdaySubmission,
          DailyWarSubmission?
        > {
  DailyWarYesterdaySubmissionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyWarYesterdaySubmissionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyWarYesterdaySubmissionHash();

  @$internal
  @override
  DailyWarYesterdaySubmission create() => DailyWarYesterdaySubmission();
}

String _$dailyWarYesterdaySubmissionHash() =>
    r'f1acf7dd036b494169c8c0471319b22202392e0b';

abstract class _$DailyWarYesterdaySubmission
    extends $AsyncNotifier<DailyWarSubmission?> {
  FutureOr<DailyWarSubmission?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<DailyWarSubmission?>, DailyWarSubmission?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DailyWarSubmission?>, DailyWarSubmission?>,
              AsyncValue<DailyWarSubmission?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(dailyWarYesterdaySnapshot)
final dailyWarYesterdaySnapshotProvider = DailyWarYesterdaySnapshotProvider._();

final class DailyWarYesterdaySnapshotProvider
    extends
        $FunctionalProvider<
          DailyWarYesterdaySnapshot,
          DailyWarYesterdaySnapshot,
          DailyWarYesterdaySnapshot
        >
    with $Provider<DailyWarYesterdaySnapshot> {
  DailyWarYesterdaySnapshotProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyWarYesterdaySnapshotProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyWarYesterdaySnapshotHash();

  @$internal
  @override
  $ProviderElement<DailyWarYesterdaySnapshot> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DailyWarYesterdaySnapshot create(Ref ref) {
    return dailyWarYesterdaySnapshot(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DailyWarYesterdaySnapshot value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DailyWarYesterdaySnapshot>(value),
    );
  }
}

String _$dailyWarYesterdaySnapshotHash() =>
    r'0334003d76594f9f94f1bedaaf5516196e6a8ce7';

/// One-shot fetch of a War by dateId (History / results) — prefers local cache.

@ProviderFor(dailyWarDocById)
final dailyWarDocByIdProvider = DailyWarDocByIdFamily._();

/// One-shot fetch of a War by dateId (History / results) — prefers local cache.

final class DailyWarDocByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailyWarDoc?>,
          DailyWarDoc?,
          FutureOr<DailyWarDoc?>
        >
    with $FutureModifier<DailyWarDoc?>, $FutureProvider<DailyWarDoc?> {
  /// One-shot fetch of a War by dateId (History / results) — prefers local cache.
  DailyWarDocByIdProvider._({
    required DailyWarDocByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'dailyWarDocByIdProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dailyWarDocByIdHash();

  @override
  String toString() {
    return r'dailyWarDocByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DailyWarDoc?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DailyWarDoc?> create(Ref ref) {
    final argument = this.argument as String;
    return dailyWarDocById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DailyWarDocByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dailyWarDocByIdHash() => r'6fbd34c16b886b68b14131ac0fed047fc2aa896b';

/// One-shot fetch of a War by dateId (History / results) — prefers local cache.

final class DailyWarDocByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DailyWarDoc?>, String> {
  DailyWarDocByIdFamily._()
    : super(
        retry: null,
        name: r'dailyWarDocByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// One-shot fetch of a War by dateId (History / results) — prefers local cache.

  DailyWarDocByIdProvider call(String dateId) =>
      DailyWarDocByIdProvider._(argument: dateId, from: this);

  @override
  String toString() => r'dailyWarDocByIdProvider';
}

/// Recent wars for History — cache-first, selective Firestore refresh.

@ProviderFor(dailyWarHistoryBundle)
final dailyWarHistoryBundleProvider = DailyWarHistoryBundleProvider._();

/// Recent wars for History — cache-first, selective Firestore refresh.

final class DailyWarHistoryBundleProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailyWarHistoryBundle>,
          DailyWarHistoryBundle,
          FutureOr<DailyWarHistoryBundle>
        >
    with
        $FutureModifier<DailyWarHistoryBundle>,
        $FutureProvider<DailyWarHistoryBundle> {
  /// Recent wars for History — cache-first, selective Firestore refresh.
  DailyWarHistoryBundleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyWarHistoryBundleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyWarHistoryBundleHash();

  @$internal
  @override
  $FutureProviderElement<DailyWarHistoryBundle> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DailyWarHistoryBundle> create(Ref ref) {
    return dailyWarHistoryBundle(ref);
  }
}

String _$dailyWarHistoryBundleHash() =>
    r'628c3bee0b18700cddf6760b8ef129956871f210';

/// Full archive for one War night (leaderboard + attempt). Local-only once ranked.

@ProviderFor(dailyWarArchive)
final dailyWarArchiveProvider = DailyWarArchiveFamily._();

/// Full archive for one War night (leaderboard + attempt). Local-only once ranked.

final class DailyWarArchiveProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailyWarArchiveBundle>,
          DailyWarArchiveBundle,
          FutureOr<DailyWarArchiveBundle>
        >
    with
        $FutureModifier<DailyWarArchiveBundle>,
        $FutureProvider<DailyWarArchiveBundle> {
  /// Full archive for one War night (leaderboard + attempt). Local-only once ranked.
  DailyWarArchiveProvider._({
    required DailyWarArchiveFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'dailyWarArchiveProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dailyWarArchiveHash();

  @override
  String toString() {
    return r'dailyWarArchiveProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DailyWarArchiveBundle> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DailyWarArchiveBundle> create(Ref ref) {
    final argument = this.argument as String;
    return dailyWarArchive(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DailyWarArchiveProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dailyWarArchiveHash() => r'4deabc9c24e48077b2109590f9f3086cd3519d2c';

/// Full archive for one War night (leaderboard + attempt). Local-only once ranked.

final class DailyWarArchiveFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DailyWarArchiveBundle>, String> {
  DailyWarArchiveFamily._()
    : super(
        retry: null,
        name: r'dailyWarArchiveProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Full archive for one War night (leaderboard + attempt). Local-only once ranked.

  DailyWarArchiveProvider call(String dateId) =>
      DailyWarArchiveProvider._(argument: dateId, from: this);

  @override
  String toString() => r'dailyWarArchiveProvider';
}

/// Questions for a War paper with the user's answers overlaid (local SQLite).

@ProviderFor(dailyWarArchiveQuestions)
final dailyWarArchiveQuestionsProvider = DailyWarArchiveQuestionsFamily._();

/// Questions for a War paper with the user's answers overlaid (local SQLite).

final class DailyWarArchiveQuestionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TestQuestion>>,
          List<TestQuestion>,
          FutureOr<List<TestQuestion>>
        >
    with
        $FutureModifier<List<TestQuestion>>,
        $FutureProvider<List<TestQuestion>> {
  /// Questions for a War paper with the user's answers overlaid (local SQLite).
  DailyWarArchiveQuestionsProvider._({
    required DailyWarArchiveQuestionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'dailyWarArchiveQuestionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dailyWarArchiveQuestionsHash();

  @override
  String toString() {
    return r'dailyWarArchiveQuestionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TestQuestion>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TestQuestion>> create(Ref ref) {
    final argument = this.argument as String;
    return dailyWarArchiveQuestions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DailyWarArchiveQuestionsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dailyWarArchiveQuestionsHash() =>
    r'f71afc7c043cea88bd11c8f803d912d999cb38d1';

/// Questions for a War paper with the user's answers overlaid (local SQLite).

final class DailyWarArchiveQuestionsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TestQuestion>>, String> {
  DailyWarArchiveQuestionsFamily._()
    : super(
        retry: null,
        name: r'dailyWarArchiveQuestionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Questions for a War paper with the user's answers overlaid (local SQLite).

  DailyWarArchiveQuestionsProvider call(String dateId) =>
      DailyWarArchiveQuestionsProvider._(argument: dateId, from: this);

  @override
  String toString() => r'dailyWarArchiveQuestionsProvider';
}

/// @deprecated Prefer [dailyWarHistoryBundleProvider] (includes submissions).

@ProviderFor(dailyWarHistoryList)
final dailyWarHistoryListProvider = DailyWarHistoryListProvider._();

/// @deprecated Prefer [dailyWarHistoryBundleProvider] (includes submissions).

final class DailyWarHistoryListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DailyWarDoc>>,
          List<DailyWarDoc>,
          FutureOr<List<DailyWarDoc>>
        >
    with
        $FutureModifier<List<DailyWarDoc>>,
        $FutureProvider<List<DailyWarDoc>> {
  /// @deprecated Prefer [dailyWarHistoryBundleProvider] (includes submissions).
  DailyWarHistoryListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyWarHistoryListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyWarHistoryListHash();

  @$internal
  @override
  $FutureProviderElement<List<DailyWarDoc>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DailyWarDoc>> create(Ref ref) {
    return dailyWarHistoryList(ref);
  }
}

String _$dailyWarHistoryListHash() =>
    r'141be6ac3778f26970be490d9ffe4168df0fdbd0';

@ProviderFor(dailyWarLiveCounts)
final dailyWarLiveCountsProvider = DailyWarLiveCountsProvider._();

final class DailyWarLiveCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailyWarLiveCounts>,
          DailyWarLiveCounts,
          Stream<DailyWarLiveCounts>
        >
    with
        $FutureModifier<DailyWarLiveCounts>,
        $StreamProvider<DailyWarLiveCounts> {
  DailyWarLiveCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyWarLiveCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyWarLiveCountsHash();

  @$internal
  @override
  $StreamProviderElement<DailyWarLiveCounts> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<DailyWarLiveCounts> create(Ref ref) {
    return dailyWarLiveCounts(ref);
  }
}

String _$dailyWarLiveCountsHash() =>
    r'b6f19a32a8c493ea540a59e76782f0dffab0fee1';
