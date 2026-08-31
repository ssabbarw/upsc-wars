import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/activation_milestones.dart';
import '../../../core/analytics/screen_flow_analytics.dart';
import '../../../core/domain/entities/answer_confidence.dart';
import '../../../core/responsive/app_breakpoints.dart';
import '../../../core/domain/entities/test_question.dart';
import '../../../core/providers/app_language_helpers.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../history/screens/session_review_screen.dart';
import '../../home/domain/demo_diagnostic_ephemeral_store.dart';
import '../providers/danger_zone_review_provider.dart';

class DangerZoneReviewScreen extends HookConsumerWidget {
  const DangerZoneReviewScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dangerZoneQuestionsProvider(sessionId));

    final hPad = AppBreakpoints.fullScreenHPadding(MediaQuery.sizeOf(context).width);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: hPad,
          child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Could not load review', style: AppTextStyles.body()),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    onPressed: () =>
                        ref.invalidate(dangerZoneQuestionsProvider(sessionId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (questions) {
            if (questions.isEmpty) {
              return _EmptyDangerZone(
                onBack: () {
                  ScreenFlow.logAction(
                    ref,
                    screenName: ScreenFlow.dangerZoneReview,
                    actionId: 'back',
                    actionKind: 'back',
                  );
                  context.pop();
                },
              );
            }
            return _DangerZonePager(sessionId: sessionId, questions: questions);
          },
        ),
        ),
      ),
    );
  }
}

class _EmptyDangerZone extends StatelessWidget {
  const _EmptyDangerZone({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(onPressed: onBack, icon: const Icon(Icons.chevron_left)),
          const Spacer(),
          Text(
            'No Danger Zone items',
            style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Wrong answers without a confidence pick, or where you marked '
            '"Guessing", do not appear here.',
            style: AppTextStyles.bodyMd().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _DangerZonePager extends HookConsumerWidget {
  const _DangerZonePager({required this.sessionId, required this.questions});

  final String sessionId;
  final List<TestQuestion> questions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = useState(0);
    final preferredLanguage = watchAppLanguage(ref);
    final uiLanguage = useState(preferredLanguage);
    final bookmarks = useState<Map<String, bool>>({});

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
        for (final q in questions) {
          map[q.uuid] = await repo.isBookmarked(q.uuid);
        }
        bookmarks.value = map;
      }

      loadBm();
      return null;
    }, [questions]);

    final q = questions[index.value];
    final total = questions.length;
    final current = index.value + 1;
    final confLabel = q.confidence == null
        ? 'Confident'
        : AnswerConfidence.displayLabel(q.confidence!);
    final isBookmarked = bookmarks.value[q.uuid] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ReviewBody(
            title: 'Danger Zone Review',
            showRevisionBadge: false,
            progressRight: '${q.subject} · ${q.topic}',
            question: q,
            current: current,
            total: total,
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
              if (index.value > 0) index.value = index.value - 1;
            },
            onNext: () {
              if (current == total) {
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
              } else {
                index.value = index.value + 1;
              }
            },
            onAddToRevision: null,
            uiLanguage: uiLanguage.value,
            onLanguageChanged: (lang) {
              uiLanguage.value = lang;
              unawaited(persistAppLanguage(ref, lang));
            },
            confidenceBanner: 'You were $confLabel',
          ),
        ),
      ],
    );
  }
}
