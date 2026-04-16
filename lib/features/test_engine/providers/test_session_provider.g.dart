// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TestSessionNotifier)
final testSessionProvider = TestSessionNotifierFamily._();

final class TestSessionNotifierProvider
    extends $AsyncNotifierProvider<TestSessionNotifier, TestSessionState> {
  TestSessionNotifierProvider._({
    required TestSessionNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'testSessionProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$testSessionNotifierHash();

  @override
  String toString() {
    return r'testSessionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TestSessionNotifier create() => TestSessionNotifier();

  @override
  bool operator ==(Object other) {
    return other is TestSessionNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$testSessionNotifierHash() =>
    r'075d8488658d63184d8fd60e008a3c0856b4ac87';

final class TestSessionNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          TestSessionNotifier,
          AsyncValue<TestSessionState>,
          TestSessionState,
          FutureOr<TestSessionState>,
          String
        > {
  TestSessionNotifierFamily._()
    : super(
        retry: null,
        name: r'testSessionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  TestSessionNotifierProvider call(String sessionId) =>
      TestSessionNotifierProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'testSessionProvider';
}

abstract class _$TestSessionNotifier extends $AsyncNotifier<TestSessionState> {
  late final _$args = ref.$arg as String;
  String get sessionId => _$args;

  FutureOr<TestSessionState> build(String sessionId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<TestSessionState>, TestSessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TestSessionState>, TestSessionState>,
              AsyncValue<TestSessionState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
