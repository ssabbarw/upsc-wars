import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/theme/app_spacing.dart';
import '../fomo_pulse_constants.dart';
import '../providers/fomo_pulse_providers.dart';
import '../widgets/fomo_pulse_mcq_panel.dart';

/// Standalone MCQ route (e.g. deep links). Detail screen uses [FomoPulseMcqPanel] inline.
class FomoPulseMcqScreen extends HookConsumerWidget {
  const FomoPulseMcqScreen({
    super.key,
    required this.pulseId,
    this.initialSelectedOption,
    this.entrySource = FomoPulseConstants.entryInApp,
  });

  final String pulseId;
  final String? initialSelectedOption;
  final String entrySource;

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
                  'Could not load this CA Shot.',
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
        data: (data) => _McqBody(
          pulseId: pulseId,
          entrySource: entrySource,
          alreadyAttempted: data.attempt?.attempted == true,
          child: FomoPulseMcqPanel(
            pulse: data.pulse,
            existingAttempt: data.attempt,
            initialSelectedOption: initialSelectedOption,
            showNavigationCtas: true,
            entrySource: entrySource,
          ),
        ),
      ),
    );
  }
}

class _McqBody extends HookConsumerWidget {
  const _McqBody({
    required this.pulseId,
    required this.entrySource,
    required this.alreadyAttempted,
    required this.child,
  });

  final String pulseId;
  final String entrySource;
  final bool alreadyAttempted;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      unawaited(
        Analytics.track(
          ref,
          CaShotMcqOpenedEvent(
            pulseId: pulseId,
            source: entrySource,
            alreadyAttempted: alreadyAttempted,
          ),
        ),
      );
      return null;
    }, [pulseId, entrySource]);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [child],
    );
  }
}
