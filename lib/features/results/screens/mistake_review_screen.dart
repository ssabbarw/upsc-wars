import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/activation_milestones.dart';
import '../../../core/analytics/screen_flow_analytics.dart';
import '../../../core/domain/entities/answer_confidence.dart';
import '../../../core/domain/entities/test_question.dart';
import '../../../core/providers/app_language_helpers.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/responsive/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../history/screens/session_review_screen.dart';
import '../domain/mistake_review_bundle.dart';
import '../providers/mistake_review_provider.dart';

enum _MistakeReviewPhase { sure, transition, eduGuess }

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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => _ReviewError(
              onRetry: () =>
                  ref.invalidate(mistakeReviewBundleProvider(sessionId)),
              onBack: () => context.pop(),
            ),
            data: (bundle) {
              if (bundle.total == 0) {
                return _ReviewError(
                  message: 'No reviewable mistakes in this session.',
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
  const _ReviewError({
    this.message = 'Could not load review.',
    this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(onPressed: onBack, icon: const Icon(Icons.chevron_left)),
        const Spacer(),
        Text(message, style: AppTextStyles.body()),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
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
      _MistakeReviewPhase.transition => const <TestQuestion>[],
    };

    useEffect(() {
      unawaited(
        logActivationMilestoneOnce(
          ref,
          ActivationMilestones.firstDangerZoneReview,
        ),
      );
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

    if (phase.value == _MistakeReviewPhase.transition) {
      final doneCount = bundle.sureWrong.length;
      return _EduGuessTransition(
        doneCount: doneCount,
        totalCount: bundle.total,
        eduCount: bundle.eduGuessWrong.length,
        onContinue: () {
          phase.value = _MistakeReviewPhase.eduGuess;
          index.value = 0;
        },
        onBack: () {
          if (bundle.sureWrong.isEmpty) {
            context.pop();
            return;
          }
          phase.value = _MistakeReviewPhase.sure;
          index.value = bundle.sureWrong.length - 1;
        },
      );
    }

    final q = activeQuestions[index.value];
    final segmentTotal = activeQuestions.length;
    final segmentCurrent = index.value + 1;
    final overallDone = switch (phase.value) {
      _MistakeReviewPhase.sure => segmentCurrent,
      _MistakeReviewPhase.eduGuess => bundle.sureWrong.length + segmentCurrent,
      _MistakeReviewPhase.transition => bundle.sureWrong.length,
    };

    final isSurePhase = phase.value == _MistakeReviewPhase.sure;
    final segmentLabel = isSurePhase
        ? 'CONFIDENT · WRONG'
        : 'EDUCATED GUESS · WRONG';
    final segmentColor = isSurePhase
        ? AppColors.coachDangerTitleText
        : AppColors.correctText;
    final isBookmarked = bookmarks.value[q.uuid] ?? false;
    final confLabel = q.confidence == null
        ? 'Confident'
        : AnswerConfidence.displayLabel(q.confidence!);

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
      isBookmarked: isBookmarked,
      isQueued: false,
      confidenceSessionId: sessionId,
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
          phase.value = _MistakeReviewPhase.transition;
          return;
        }
        ScreenFlow.logAction(
          ref,
          screenName: ScreenFlow.dangerZoneReview,
          actionId: 'exit_pager',
          actionKind: 'back',
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
      onAddToRevision: null,
      uiLanguage: uiLanguage.value,
      onLanguageChanged: (lang) {
        uiLanguage.value = lang;
        unawaited(persistAppLanguage(ref, lang));
      },
      confidenceBanner: 'You were $confLabel',
    );
  }
}

class _EduTransitionBulletBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const bullets = [
      'Topics that need focused revision',
      'Concepts partially encountered but not fully absorbed',
      'Areas where elimination logic needs strengthening',
    ];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8F0),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•  ',
                    style: AppTextStyles.bodySm().copyWith(
                      color: AppColors.correctText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      bullet,
                      style: AppTextStyles.bodySm().copyWith(
                        color: AppColors.correctText,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EduGuessTransition extends StatelessWidget {
  const _EduGuessTransition({
    required this.doneCount,
    required this.totalCount,
    required this.eduCount,
    required this.onContinue,
    required this.onBack,
  });

  final int doneCount;
  final int totalCount;
  final int eduCount;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Review',
                    style: AppTextStyles.h3().copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    '$doneCount of $totalCount done',
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F8F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 36,
                    color: AppColors.correctText,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'UP NEXT · EDUCATED GUESS · WRONG',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption().copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.correctText,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '$eduCount question${eduCount == 1 ? '' : 's'} where your guess didn\'t pay off',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h2().copyWith(
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'You knew you weren\'t sure on these. Clean gaps — easier to fix than confident mistakes.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _EduTransitionBulletBox(),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.onSurface,
              side: const BorderSide(color: AppColors.summaryButtonBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            onPressed: onContinue,
            child: Text(
              'Continue  →',
              style: AppTextStyles.label().copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
