// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_war_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(dailyWarTodayDoc)
final dailyWarTodayDocProvider = DailyWarTodayDocProvider._();

/// Live Firestore snapshot for today's War (null if missing).

final class DailyWarTodayDocProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailyWarDoc?>,
          DailyWarDoc?,
          Stream<DailyWarDoc?>
        >
    with $FutureModifier<DailyWarDoc?>, $StreamProvider<DailyWarDoc?> {
  /// Live Firestore snapshot for today's War (null if missing).
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

String _$dailyWarTodayDocHash() => r'e8a69a106da1fffb3032da2903caf117728c45f5';

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
    r'f99f0e3f70fdbb730a5d45932126bd60ae86e5d1';

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
    r'037e01e33fa35a17f853fafc6bbf8f69c0a17f7e';

/// One-shot fetch of a War by dateId (History).

@ProviderFor(dailyWarDocById)
final dailyWarDocByIdProvider = DailyWarDocByIdFamily._();

/// One-shot fetch of a War by dateId (History).

final class DailyWarDocByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailyWarDoc?>,
          DailyWarDoc?,
          FutureOr<DailyWarDoc?>
        >
    with $FutureModifier<DailyWarDoc?>, $FutureProvider<DailyWarDoc?> {
  /// One-shot fetch of a War by dateId (History).
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

String _$dailyWarDocByIdHash() => r'0267dc5bc648dcfad40f3ed9f4e756e2e933fb31';

/// One-shot fetch of a War by dateId (History).

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

  /// One-shot fetch of a War by dateId (History).

  DailyWarDocByIdProvider call(String dateId) =>
      DailyWarDocByIdProvider._(argument: dateId, from: this);

  @override
  String toString() => r'dailyWarDocByIdProvider';
}

/// Recent wars for History (newest first). Limited query.

@ProviderFor(dailyWarHistoryList)
final dailyWarHistoryListProvider = DailyWarHistoryListProvider._();

/// Recent wars for History (newest first). Limited query.

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
  /// Recent wars for History (newest first). Limited query.
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
    r'889415a59288b380c856cdddab6288b33a80dd42';
