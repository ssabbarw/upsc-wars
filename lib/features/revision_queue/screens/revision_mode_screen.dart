import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/core/providers/catalog_providers.dart';
import 'package:upsc_wars/features/history/providers/review_session_provider.dart';
import 'package:upsc_wars/features/history/screens/session_review_screen.dart';

class RevisionModeScreen extends HookConsumerWidget {
  const RevisionModeScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(reviewSessionProvider(sessionId));
    return Scaffold(
      body: SafeArea(
        child: review.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (e, st) => Center(
                child: FilledButton(
                  onPressed:
                      () => ref.invalidate(reviewSessionProvider(sessionId)),
                  child: const Text('Retry'),
                ),
              ),
          data: (state) {
            final index = useState(0);
            final uiLanguage = useState('en');
            final bookmarks = useState<Map<String, bool>>(
              state.bookmarkedByUuid,
            );
            final q = state.questions[index.value];
            final total = state.total;
            final current = index.value + 1;
            final isBookmarked = bookmarks.value[q.uuid] ?? false;
            return ReviewBody(
              title: 'Revision',
              showRevisionBadge: true,
              progressRight: 'Revision queue',
              question: q,
              current: current,
              total: total,
              isBookmarked: isBookmarked,
              isQueued: true,
              isRevisionMode: true,
              onToggleBookmark: () async {
                final repo = await ref.read(
                  testEngineRepositoryProvider.future,
                );
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
              uiLanguage: uiLanguage.value,
              onLanguageChanged: (lang) => uiLanguage.value = lang,
            );
          },
        ),
      ),
    );
  }
}
