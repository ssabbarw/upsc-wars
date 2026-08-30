import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/domain/demo_session_warmup.dart';
import '../providers/test_session_provider.dart';
import '../widgets/test_engine_question_shimmer.dart';
import 'test_engine_screen.dart';

/// Opens immediately on the demo CTA; swaps in [TestEngineScreen] when the
/// background-created session is ready.
class DemoTestLaunchScreen extends HookConsumerWidget {
  const DemoTestLaunchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionId = useState<String?>(DemoSessionWarmup.readyId);
    final error = useState<Object?>(null);
    final attempt = useState(0);

    useEffect(() {
      if (sessionId.value != null) return null;
      var cancelled = false;
      final container = ProviderScope.containerOf(context, listen: false);
      unawaited(() async {
        try {
          final id = await DemoSessionWarmup.ensure(
            () => DemoSessionWarmup.loadSession(container),
          );
          await container.read(testSessionProvider(id).future);
          if (!cancelled) sessionId.value = id;
        } on Object catch (e) {
          if (!cancelled) error.value = e;
        }
      }());
      return () => cancelled = true;
    }, [attempt.value]);

    if (sessionId.value != null) {
      return TestEngineScreen(sessionId: sessionId.value!);
    }

    return Scaffold(
      body: SafeArea(
        child: error.value != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Could not load the demo test.',
                        style: AppTextStyles.body(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      OutlinedButton(
                        onPressed: () {
                          DemoSessionWarmup.reset();
                          error.value = null;
                          attempt.value++;
                        },
                        child: Text('Retry', style: AppTextStyles.label()),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: () => context.go('/'),
                        child: Text('Home', style: AppTextStyles.label()),
                      ),
                    ],
                  ),
                ),
              )
            : const TestEngineQuestionShimmer(),
      ),
    );
  }
}
