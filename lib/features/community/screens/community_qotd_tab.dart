import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/prefs_provider.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/qotd_providers.dart';
import '../widgets/qotd_post_card.dart';

String _qotdNormLang(String? code) =>
    (code ?? 'en').toLowerCase().trim() == 'hi' ? 'hi' : 'en';

class CommunityQotdTab extends HookConsumerWidget {
  const CommunityQotdTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final prefs = ref.watch(prefsServiceProvider).value;
    final tabLangOverride = useState<String?>(null);
    final uiLang = _qotdNormLang(
      tabLangOverride.value ?? prefs?.language ?? 'en',
    );

    final feed = ref.watch(qotdFeedNotifierProvider);
    final scroll = useScrollController();

    useEffect(() {
      void onScroll() {
        if (!scroll.hasClients) return;
        final pos = scroll.position;
        if (pos.pixels >= pos.maxScrollExtent - 280) {
          ref.read(qotdFeedNotifierProvider.notifier).loadMore();
        }
      }

      scroll.addListener(onScroll);
      return () => scroll.removeListener(onScroll);
    }, [scroll, ref]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.quiz_outlined, color: scheme.primary, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question of the day',
                      style: AppTextStyles.h3().copyWith(
                        color: scheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Share a tough question with the Community. Tap a card to expand, '
                      'react, and attempt.',
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.tonal(
                    onPressed: () => context.push('/community/qotd/post'),
                    child: const Text('✨ Create'),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ToggleButtons(
                    isSelected: [uiLang == 'en', uiLang == 'hi'],
                    onPressed: (i) =>
                        tabLangOverride.value = i == 0 ? 'en' : 'hi',
                    constraints: const BoxConstraints(
                      minHeight: 32,
                      minWidth: 60,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('EN'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('हि'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: feed.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Could not load QOTD feed',
                      style: AppTextStyles.bodyMd(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '$e',
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () => ref.invalidate(qotdFeedNotifierProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (view) {
              final posts = view.posts;
              if (posts.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(qotdFeedNotifierProvider.notifier).refresh(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    children: [
                      Text(
                        'No questions shared yet. Pull to refresh, or tap Create '
                        'to post one (for example after you attempt a question in '
                        'a test).',
                        style: AppTextStyles.bodyMd().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(qotdFeedNotifierProvider.notifier).refresh(),
                child: ListView.builder(
                  controller: scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  itemCount: posts.length + (view.hasMore ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i >= posts.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return QotdPostCard(post: posts[i], uiLanguage: uiLang);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
