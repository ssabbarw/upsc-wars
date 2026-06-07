import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/responsive/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/mistake_review_bundle.dart';
import '../providers/mistake_review_provider.dart';
import '../widgets/mistake_review_carousel_card.dart';

class MistakeReviewIntroScreen extends HookConsumerWidget {
  const MistakeReviewIntroScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mistakeReviewBundleProvider(sessionId));
    final hPad = AppBreakpoints.fullScreenHPadding(
      MediaQuery.sizeOf(context).width,
    );
    final contentPad = hPad.left == 0 && hPad.right == 0
        ? const EdgeInsets.symmetric(horizontal: AppSpacing.lg)
        : hPad;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: contentPad,
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => _IntroError(
              onRetry: () =>
                  ref.invalidate(mistakeReviewBundleProvider(sessionId)),
              onBack: () => context.pop(),
            ),
            data: (bundle) {
              if (bundle.total == 0) {
                return _IntroError(
                  message: 'No reviewable mistakes in this session.',
                  onBack: () => context.pop(),
                );
              }
              return _IntroBody(sessionId: sessionId, bundle: bundle);
            },
          ),
        ),
      ),
    );
  }
}

class _IntroError extends StatelessWidget {
  const _IntroError({
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

class _IntroBody extends HookWidget {
  const _IntroBody({required this.sessionId, required this.bundle});

  final String sessionId;
  final MistakeReviewBundle bundle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pageController = usePageController();
    final pageIndex = useState(0);

    final cards = <MistakeReviewCarouselKind>[];
    if (bundle.hasSureWrong) {
      cards.add(MistakeReviewCarouselKind.sureWrong);
    }
    if (bundle.hasEduGuessWrong) {
      cards.add(MistakeReviewCarouselKind.eduGuessWrong);
    }

    final title = bundle.hasSureWrong
        ? 'Review confident mistakes'
        : 'Review your mistakes';

    int countFor(MistakeReviewCarouselKind kind) => switch (kind) {
      MistakeReviewCarouselKind.sureWrong => bundle.sureWrong.length,
      MistakeReviewCarouselKind.eduGuessWrong => bundle.eduGuessWrong.length,
    };

    Color dotColor(MistakeReviewCarouselKind kind) =>
        kind == MistakeReviewCarouselKind.sureWrong
        ? AppColors.coachDangerBorder
        : AppColors.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.h3().copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const Divider(height: 1),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'THIS SESSION',
          style: AppTextStyles.caption().copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'You lost marks on ${bundle.total} question${bundle.total == 1 ? '' : 's'}',
          style: AppTextStyles.h2().copyWith(
            fontWeight: FontWeight.w900,
            color: scheme.onSurface,
          ),
        ),
        if (cards.length > 1) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Swipe to see both types',
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: PageView.builder(
            controller: pageController,
            itemCount: cards.length,
            onPageChanged: (i) => pageIndex.value = i,
            itemBuilder: (context, index) {
              final kind = cards[index];
              return MistakeReviewCarouselCard(
                kind: kind,
                count: countFor(kind),
              );
            },
          ),
        ),
        if (cards.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < cards.length; i++)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pageIndex.value == i
                        ? dotColor(cards[i])
                        : scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.onSurface,
              side: BorderSide(color: AppColors.summaryButtonBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/mistake-review/$sessionId');
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              'Start review',
              style: AppTextStyles.label().copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
