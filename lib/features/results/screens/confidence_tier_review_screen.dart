import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/answer_confidence.dart';
import '../../../core/domain/entities/test_question.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../history/screens/session_review_screen.dart';
import '../providers/confidence_tier_review_provider.dart';

class ConfidenceTierReviewScreen extends HookConsumerWidget {
  const ConfidenceTierReviewScreen({
    super.key,
    required this.sessionId,
    required this.tier,
    this.outcomeFilter,
  });

  final String sessionId;
  /// One of [AnswerConfidence.verySure], [somewhatSure], [guessing].
  final String tier;

  /// When set to `correct` or `wrong`, only those outcomes are listed.
  final String? outcomeFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!AnswerConfidence.values.contains(tier)) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Text(
                'Invalid confidence filter.',
                style: AppTextStyles.body(),
              ),
            ),
          ),
        ),
      );
    }

    final async = ref.watch(
      confidenceTierQuestionsProvider((
        sessionId: sessionId,
        tier: tier,
        outcomeFilter: outcomeFilter,
      )),
    );

    return Scaffold(
      body: SafeArea(
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
                    onPressed: () => ref.invalidate(
                      confidenceTierQuestionsProvider((
                        sessionId: sessionId,
                        tier: tier,
                        outcomeFilter: outcomeFilter,
                      )),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (questions) {
            if (questions.isEmpty) {
              return _EmptyTierReview(
                tier: tier,
                outcomeFilter: outcomeFilter,
                onBack: () => context.pop(),
              );
            }
            return _TierPager(
              sessionId: sessionId,
              tier: tier,
              outcomeFilter: outcomeFilter,
              questions: questions,
            );
          },
        ),
      ),
    );
  }
}

class _EmptyTierReview extends StatelessWidget {
  const _EmptyTierReview({
    required this.tier,
    required this.outcomeFilter,
    required this.onBack,
  });

  final String tier;
  final String? outcomeFilter;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = AnswerConfidence.examShortLabel(tier);
    final outcomeLine = outcomeFilter == null
        ? ''
        : ' with outcome “$outcomeFilter”';
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(onPressed: onBack, icon: const Icon(Icons.chevron_left)),
          const Spacer(),
          Text(
            'No $label items',
            style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No scored questions in this session were logged under “$label”$outcomeLine.',
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

class _TierPager extends HookConsumerWidget {
  const _TierPager({
    required this.sessionId,
    required this.tier,
    required this.outcomeFilter,
    required this.questions,
  });

  final String sessionId;
  final String tier;
  final String? outcomeFilter;
  final List<TestQuestion> questions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = useState(0);
    final uiLanguage = useState('en');
    final bookmarks = useState<Map<String, bool>>({});

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
    final tierLabel = AnswerConfidence.examShortLabel(tier);
    final isBookmarked = bookmarks.value[q.uuid] ?? false;
    final filterSuffix = outcomeFilter == null
        ? ''
        : ' · ${outcomeFilter == 'wrong' ? 'Wrong only' : 'Correct only'}';

    return ReviewBody(
      title: '$tierLabel · Review$filterSuffix',
      showRevisionBadge: false,
      progressRight: '${q.subject} · ${q.topic}',
      question: q,
      current: current,
      total: total,
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
        if (index.value > 0) index.value = index.value - 1;
      },
      onNext: () {
        if (current == total) {
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
      onLanguageChanged: (lang) => uiLanguage.value = lang,
      confidenceBanner: 'Logged as: $tierLabel$filterSuffix',
    );
  }
}
