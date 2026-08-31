import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../test_engine/providers/test_session_provider.dart';
import 'create_get_started_session_use_case.dart';

/// Shared in-flight create for the first-run demo test.
///
/// Onboarding starts this immediately so the post-onboarding intro can open
/// the test shell before the session row exists. [ensure] is the only create path so
/// two callers cannot insert two sessions.
abstract final class DemoSessionWarmup {
  static const pendingRoute = '/test/pending-demo';

  static Future<String>? _inFlight;
  static int _generation = 0;
  static String? readyId;

  static void start(Future<String> Function() create) {
    _inFlight ??= _wrap(create);
  }

  static Future<String> ensure(Future<String> Function() create) {
    start(create);
    return _inFlight!;
  }

  /// Create (or reuse) the demo session and load questions into [testSessionProvider].
  static Future<String> loadSession(ProviderContainer container) async {
    final uc = await container.read(
      createGetStartedSessionUseCaseProvider.future,
    );
    final id = await uc.executeMixed();
    await container.read(testSessionProvider(id).future);
    return id;
  }

  static void reset() {
    _generation++;
    _inFlight = null;
    readyId = null;
  }

  static Future<String> _wrap(Future<String> Function() create) {
    final gen = _generation;
    return () async {
      final id = await create();
      if (gen != _generation) {
        throw StateError('Demo session warmup was reset');
      }
      readyId = id;
      return id;
    }();
  }
}
