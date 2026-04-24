import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/session_result.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../open_challenge/open_challenge_analytics.dart';
import '../open_challenge/open_challenge_exam_registry.dart';
import '../open_challenge/open_challenge_post_results_submit.dart';
import '../../../shared/widgets/app_toast.dart';

/// Open-challenge **create** only: auto-publishes from [ResultsScreen].
/// Accept flow uses [OpenChallengeAcceptResultsShell] instead.
class OpenChallengeResultsActions extends ConsumerStatefulWidget {
  const OpenChallengeResultsActions({
    super.key,
    required this.sessionId,
    required this.result,
  });

  final String sessionId;
  final SessionResult result;

  @override
  ConsumerState<OpenChallengeResultsActions> createState() =>
      _OpenChallengeResultsActionsState();
}

class _OpenChallengeResultsActionsState
    extends ConsumerState<OpenChallengeResultsActions> {
  var _busy = false;
  var _autoSubmitScheduled = false;
  var _failed = false;
  String? _cooldownMessage;

  bool get _eligible =>
      widget.result.analyticsFeatureKey == OpenChallengeAnalytics.create;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_eligible || _autoSubmitScheduled) return;
      final ctx = ref
          .read(openChallengeExamRegistryProvider)
          .peek(widget.sessionId);
      if (ctx == null) return;
      _autoSubmitScheduled = true;
      setState(() => _failed = false);
      unawaited(_submit(context));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_eligible) return const SizedBox.shrink();
    if (ref.read(openChallengeExamRegistryProvider).peek(widget.sessionId) ==
        null) {
      return const SizedBox.shrink();
    }

    final cooldown = _cooldownMessage;
    if (cooldown != null) {
      final scheme = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.schedule_rounded, color: scheme.secondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  cooldown,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSecondaryContainer,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_busy) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Publishing your challenge…',
                style: AppTextStyles.bodySm().copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_failed) {
      final scheme = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.errorContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Could not complete this step. Check your connection and try again.',
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () {
                  setState(() => _failed = false);
                  unawaited(_submit(context));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _submit(BuildContext context) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await performOpenChallengePostResultsPublish(
        ref: ref,
        context: context,
        sessionId: widget.sessionId,
        result: widget.result,
      );
    } on OpenChallengePublishCooldownException catch (e) {
      if (mounted) setState(() => _cooldownMessage = e.bodyCopy);
    } catch (e) {
      if (context.mounted) {
        final msg = '$e'.contains('already_attempted')
            ? 'You have already attempted this challenge.'
            : '$e'.contains('challenge_expired')
                ? 'This challenge has expired.'
                : '$e';
        AppToast.showText(context, msg);
      }
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
