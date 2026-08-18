import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/admin_dashboard/admin_dashboard_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../test_engine/providers/test_session_provider.dart';
import '../../test_engine/screens/test_engine_screen.dart';
import '../data/fomo_pulse_test_session_launcher.dart';
import '../domain/fomo_pulse_models.dart';
import '../providers/fomo_pulse_providers.dart';

/// Full-screen MCQ experience for a Fomo Pulse.
///
/// This host launches a one-question learning session in the existing
/// TestEngine flow, then syncs the first attempt to FOMO pulse backend.
class FomoPulseMcqScreen extends HookConsumerWidget {
  const FomoPulseMcqScreen({super.key, required this.pulseId});

  final String pulseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(fomoPulseDetailProvider(pulseId));

    return Scaffold(
      appBar: AppBar(title: const Text('Attempt')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 48),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Could not load this Pulse.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: () =>
                      ref.invalidate(fomoPulseDetailProvider(pulseId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (data) => _FomoPulseLearningEngineHost(
          pulse: data.pulse,
          existingAttempt: data.attempt,
          pulseId: pulseId,
        ),
      ),
    );
  }
}

class _FomoPulseLearningEngineHost extends HookConsumerWidget {
  const _FomoPulseLearningEngineHost({
    required this.pulse,
    required this.existingAttempt,
    required this.pulseId,
  });

  final FomoPulse pulse;
  final FomoPulseAttemptState? existingAttempt;
  final String pulseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launch = ref.watch(fomoPulseTestSessionLauncherProvider);
    final createdSessionId = useState<String?>(null);
    final launchError = useState<Object?>(null);
    final launching = useRef(false);

    useEffect(() {
      if (createdSessionId.value != null || launching.value) return null;
      final launcher = launch.asData?.value;
      if (launcher == null) return null;
      launching.value = true;
      unawaited(() async {
        try {
          final sessionId = await launcher.createLearningSession(pulse);
          if (!context.mounted) return;
          createdSessionId.value = sessionId;
          launchError.value = null;
        } catch (e) {
          if (!context.mounted) return;
          launchError.value = e;
        } finally {
          launching.value = false;
        }
      }());
      return null;
    }, [launch, pulse.pulseId]);

    if (launch.isLoading || createdSessionId.value == null) {
      final err = launchError.value ?? launch.error;
      if (err != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Could not open the test.',
                  style: AppTextStyles.label(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$err',
                  style: AppTextStyles.caption(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () {
                    launchError.value = null;
                    launching.value = false;
                    ref.invalidate(fomoPulseTestSessionLauncherProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    return _FomoPulseAttemptSyncBridge(
      sessionId: createdSessionId.value!,
      pulseId: pulseId,
      pulse: pulse,
      alreadyAttempted: existingAttempt?.attempted == true,
    );
  }
}

class _FomoPulseAttemptSyncBridge extends HookConsumerWidget {
  const _FomoPulseAttemptSyncBridge({
    required this.sessionId,
    required this.pulseId,
    required this.pulse,
    required this.alreadyAttempted,
  });

  final String sessionId;
  final String pulseId;
  final FomoPulse pulse;
  final bool alreadyAttempted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(testSessionProvider(sessionId));
    final didSync = useRef(alreadyAttempted);

    Future<void> syncAttempt({
      required String selectedOption,
      required int timeSpentSecs,
    }) async {
      final repo = ref.read(fomoPulseRepositoryProvider);
      final cloud = ref.read(fomoPulseCloudServiceProvider);
      final local = FomoPulseSubmitResult(
        isCorrect:
            selectedOption.toLowerCase() ==
            pulse.question.correctOption.toLowerCase(),
        selectedOption: selectedOption,
        correctOption: pulse.question.correctOption,
        alreadyAttempted: false,
        timeSpentSecs: timeSpentSecs,
      );
      await repo.recordLocalAttempt(
        pulseId: pulseId,
        result: local,
        updateCommunityCounts: false,
      );
      try {
        final remote = await cloud.submitAttempt(
          pulseId: pulseId,
          selectedOption: selectedOption,
          timeSpentSecs: timeSpentSecs,
        );
        await repo.recordLocalAttempt(pulseId: pulseId, result: remote);
        if (!remote.alreadyAttempted) {
          unawaited(AdminDashboardWriterService().recordFomoPulseEngagement());
        }
      } catch (_) {}
      ref.invalidate(fomoPulseDetailProvider(pulseId));
      ref.invalidate(fomoPulseHistoryProvider);
    }

    useEffect(() {
      if (didSync.value) return null;
      final session = async.asData?.value.session;
      if (session == null || session.questions.isEmpty) return null;
      final q = session.questions.first;
      final done = q.status == 'correct' || q.status == 'wrong';
      final selected = q.selectedOption?.trim() ?? '';
      if (!done || selected.isEmpty) return null;
      didSync.value = true;
      final secs = (q.timeSpentSecs ?? 0).clamp(1, 600);
      unawaited(syncAttempt(selectedOption: selected, timeSpentSecs: secs));
      return null;
    }, [async]);

    return TestEngineScreen(sessionId: sessionId);
  }
}
