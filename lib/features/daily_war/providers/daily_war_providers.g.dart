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

/// Auth uid for Daily War listeners — rebuilds streams when sign-in changes.
///
/// Firestore rules require `signedIn()`; without watching auth, a keepAlive
/// stream that errored before auth was ready stays empty forever.

@ProviderFor(dailyWarAuthUid)
final dailyWarAuthUidProvider = DailyWarAuthUidProvider._();

/// Auth uid for Daily War listeners — rebuilds streams when sign-in changes.
///
/// Firestore rules require `signedIn()`; without watching auth, a keepAlive
/// stream that errored before auth was ready stays empty forever.

final class DailyWarAuthUidProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  /// Auth uid for Daily War listeners — rebuilds streams when sign-in changes.
  ///
  /// Firestore rules require `signedIn()`; without watching auth, a keepAlive
  /// stream that errored before auth was ready stays empty forever.
  DailyWarAuthUidProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyWarAuthUidProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyWarAuthUidHash();

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    return dailyWarAuthUid(ref);
  }
}

String _$dailyWarAuthUidHash() => r'1607f38b382c0888836194462dc7b14fa3b1348b';

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

/// Live Firestore snapshot for today's War (null if missing).
/// Writes through to [DailyWarLocalCache] whenever data arrives.

@ProviderFor(dailyWarTodayDoc)
final dailyWarTodayDocProvider = DailyWarTodayDocProvider._();

/// Live Firestore snapshot for today's War (null if missing).
/// Writes through to [DailyWarLocalCache] whenever data arrives.

final class DailyWarTodayDocProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailyWarDoc?>,
          DailyWarDoc?,
          Stream<DailyWarDoc?>
        >
    with $FutureModifier<DailyWarDoc?>, $StreamProvider<DailyWarDoc?> {
  /// Live Firestore snapshot for today's War (null if missing).
  /// Writes through to [DailyWarLocalCache] whenever data arrives.
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
  $StreamProviderElement<DailyWarDoc?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<DailyWarDoc?> create(Ref ref) {
    return dailyWarTodayDoc(ref);
  }
}

String _$dailyWarTodayDocHash() => r'5b1bc2bffe0a207a9a62e59ec1f170f451f8b7b4';

/// Signed-in user's submission for today, if any.

@ProviderFor(dailyWarTodaySubmission)
final dailyWarTodaySubmissionProvider = DailyWarTodaySubmissionProvider._();

/// Signed-in user's submission for today, if any.

final class DailyWarTodaySubmissionProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailyWarSubmission?>,
          DailyWarSubmission?,
          Stream<DailyWarSubmission?>
        >
    with
        $FutureModifier<DailyWarSubmission?>,
        $StreamProvider<DailyWarSubmission?> {
  /// Signed-in user's submission for today, if any.
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
  $StreamProviderElement<DailyWarSubmission?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<DailyWarSubmission?> create(Ref ref) {
    return dailyWarTodaySubmission(ref);
  }
}

String _$dailyWarTodaySubmissionHash() =>
    r'e843b256c897020d8cad3085dd37bddd51f2ae61';

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

@ProviderFor(dailyWarYesterdayDoc)
final dailyWarYesterdayDocProvider = DailyWarYesterdayDocProvider._();

final class DailyWarYesterdayDocProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailyWarDoc?>,
          DailyWarDoc?,
          Stream<DailyWarDoc?>
        >
    with $FutureModifier<DailyWarDoc?>, $StreamProvider<DailyWarDoc?> {
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
  $StreamProviderElement<DailyWarDoc?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<DailyWarDoc?> create(Ref ref) {
    return dailyWarYesterdayDoc(ref);
  }
}

String _$dailyWarYesterdayDocHash() =>
    r'b24eb845b8eb6ca50211325ce773b6a9ef267293';

@ProviderFor(dailyWarYesterdaySubmission)
final dailyWarYesterdaySubmissionProvider =
    DailyWarYesterdaySubmissionProvider._();

final class DailyWarYesterdaySubmissionProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailyWarSubmission?>,
          DailyWarSubmission?,
          Stream<DailyWarSubmission?>
        >
    with
        $FutureModifier<DailyWarSubmission?>,
        $StreamProvider<DailyWarSubmission?> {
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
  $StreamProviderElement<DailyWarSubmission?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<DailyWarSubmission?> create(Ref ref) {
    return dailyWarYesterdaySubmission(ref);
  }
}

String _$dailyWarYesterdaySubmissionHash() =>
    r'b3f9d6b860ce9f3803cfbeae6c408f400deb177b';

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
