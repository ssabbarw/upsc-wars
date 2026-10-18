import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/activation_milestones.dart';
import '../../../core/analytics/screen_flow_analytics.dart';
import '../../../core/providers/app_language_helpers.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/responsive/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../history/screens/session_review_screen.dart';
import '../../home/domain/demo_diagnostic_ephemeral_store.dart';
import '../domain/mistake_review_bundle.dart';
import '../providers/mistake_review_provider.dart';
import '../../../l10n/l10n.dart';

enum _MistakeReviewPhase { sure, eduGuess }

class MistakeReviewScreen extends HookConsumerWidget {
  const MistakeReviewScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mistakeReviewBundleProvider(sessionId));
    final hPad = AppBreakpoints.fullScreenHPadding(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: hPad,
          child: async.when(
            loading: () => Center(child: CircularProgressIndicator()),
            error: (_, _) => _ReviewError(
              onRetry: () =>
                  ref.invalidate(mistakeReviewBundleProvider(sessionId)),
              onBack: () => context.pop(),
            ),
            data: (bundle) {
              if (bundle.total == 0) {
                return _ReviewError(
                  message: context.l10n.resultsNoReviewable,
                  onBack: () => context.pop(),
                );
              }
              return _MistakeReviewFlow(sessionId: sessionId, bundle: bundle);
            },
          ),
        ),
      ),
    );
  }
}

class _ReviewError extends StatelessWidget {
  const _ReviewError({this.message, this.onRetry, required this.onBack});

  final String? message;
  final VoidCallback? onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(onPressed: onBack, icon: const Icon(Icons.chevron_left)),
        const Spacer(),
        Text(
          message ?? context.l10n.resultsReviewLoadFailedDot,
          style: AppTextStyles.body(),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(context.l10n.commonRetry),
          ),
        ],
        const Spacer(),
      ],
    );
  }
}

class _MistakeReviewFlow extends HookConsumerWidget {
  const _MistakeReviewFlow({required this.sessionId, required this.bundle});

  final String sessionId;
  final MistakeReviewBundle bundle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialPhase = bundle.hasSureWrong
        ? _MistakeReviewPhase.sure
        : _MistakeReviewPhase.eduGuess;
    final phase = useState(initialPhase);
    final index = useState(0);
    final preferredLanguage = watchAppLanguage(ref);
    final uiLanguage = useState(preferredLanguage);
    final bookmarks = useState<Map<String, bool>>({});

    final activeQuestions = switch (phase.value) {
      _MistakeReviewPhase.sure => bundle.sureWrong,
      _MistakeReviewPhase.eduGuess => bundle.eduGuessWrong,
    };

    useEffect(() {
      maybeMarkDemoDiagnosticReviewOpened(sessionId);
      unawaited(
        logActivationMilestoneOnce(
          ref,
          ActivationMilestones.firstDangerZoneReview,
        ),
      );
      if (DemoDiagnosticEphemeralStore.instance.peek(sessionId) != null) {
        unawaited(logDemoReviewOpened(ref, kind: 'mistakes'));
      }
      return null;
    }, const []);

    useEffect(() {
      Future<void> loadBm() async {
        final repo = await ref.read(testEngineRepositoryProvider.future);
        final map = <String, bool>{};
        for (final q in bundle.orderedQuestions) {
          map[q.uuid] = await repo.isBookmarked(q.uuid);
        }
        bookmarks.value = map;
      }

      loadBm();
      return null;
    }, [bundle]);

    final q = activeQuestions[index.value];
    final segmentTotal = activeQuestions.length;
    final segmentCurrent = index.value + 1;
    final overallDone = switch (phase.value) {
      _MistakeReviewPhase.sure => segmentCurrent,
      _MistakeReviewPhase.eduGuess => bundle.sureWrong.length + segmentCurrent,
    };

    final isSurePhase = phase.value == _MistakeReviewPhase.sure;
    final segmentLabel = isSurePhase
        ? context.l10n.resultsSureWrongSeg
        : context.l10n.resultsEduWrongSeg;
    final segmentColor = isSurePhase
        ? AppColors.coachDangerTitleText
        : AppColors.warningText;
    final isBookmarked = bookmarks.value[q.uuid] ?? false;
    final isLastPage =
        segmentCurrent == segmentTotal &&
        !(isSurePhase && bundle.hasEduGuessWrong);

    return ReviewBody(
      title: 'Review',
      showRevisionBadge: false,
      progressRight: '${q.subject} · ${q.topic}',
      question: q,
      current: segmentCurrent,
      total: segmentTotal,
      progressSummary: '$overallDone of ${bundle.total} done',
      segmentLabel: segmentLabel,
      segmentColor: segmentColor,
      isLastPage: isLastPage,
      isBookmarked: isBookmarked,
      isQueued: false,
      confidenceSessionId: sessionId,
      analyticsSource:
          DemoDiagnosticEphemeralStore.instance.peek(sessionId) != null
          ? 'demo_review'
          : 'mistake_review',
      onToggleBookmark: () async {
        final repo = await ref.read(testEngineRepositoryProvider.future);
        if (isBookmarked) {
          await repo.removeBookmark(q.uuid);
        } else {
          await repo.addBookmark(q.uuid);
        }
        bookmarks.value = {...bookmarks.value, q.uuid: !isBookmarked};
      },
      onPrev: () {
        if (index.value > 0) {
          index.value = index.value - 1;
          return;
        }
        if (phase.value == _MistakeReviewPhase.eduGuess &&
            bundle.sureWrong.isNotEmpty) {
          phase.value = _MistakeReviewPhase.sure;
          index.value = bundle.sureWrong.length - 1;
        }
      },
      onNext: () {
        final isLastInSegment = segmentCurrent == segmentTotal;
        if (!isLastInSegment) {
          index.value = index.value + 1;
          return;
        }
        if (phase.value == _MistakeReviewPhase.sure &&
            bundle.hasEduGuessWrong) {
          phase.value = _MistakeReviewPhase.eduGuess;
          index.value = 0;
          return;
        }
        ScreenFlow.logAction(
          ref,
          screenName: ScreenFlow.dangerZoneReview,
          actionId: 'exit_pager',
          actionKind: 'back',
        );
        context.go('/results/$sessionId');
      },
      onAddToRevision: null,
      uiLanguage: uiLanguage.value,
      onLanguageChanged: (lang) {
        uiLanguage.value = lang;
        unawaited(persistAppLanguage(ref, lang));
      },
    );
  }
}
