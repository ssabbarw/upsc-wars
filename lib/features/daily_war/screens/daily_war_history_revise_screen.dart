import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/app_language_helpers.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../history/screens/session_review_screen.dart';
import '../providers/daily_war_providers.dart';
import '../theme/daily_war_theme.dart';
import '../../../l10n/l10n.dart';

/// Revise a past War paper using [ReviewBody] with attempt overlays.
class DailyWarHistoryReviseScreen extends HookConsumerWidget {
  const DailyWarHistoryReviseScreen({
    super.key,
    required this.dateId,
    this.initialIndex = 0,
  });

  final String dateId;
  final int initialIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dailyWarArchiveQuestionsProvider(dateId));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: async.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: DwColors.crimson),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$e', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(
                      dailyWarArchiveQuestionsProvider(dateId),
                    ),
                    child: Text(context.l10n.commonRetry),
                  ),
                ],
              ),
            ),
          ),
          data: (questions) {
            final start = questions.isEmpty
                ? 0
                : initialIndex.clamp(0, questions.length - 1);
            final index = useState(start);
            final preferredLanguage = watchAppLanguage(ref);
            final uiLanguage = useState(preferredLanguage);
            final bookmarks = useState<Map<String, bool>>({});
            final queued = useState<Map<String, bool>>({});

            useEffect(() {
              if (questions.isEmpty) return null;
              unawaited(() async {
                final repo = await ref.read(
                  testEngineRepositoryProvider.future,
                );
                final map = <String, bool>{};
                for (final q in questions) {
                  map[q.uuid] = await repo.isBookmarked(q.uuid);
                }
                if (context.mounted) bookmarks.value = map;
              }());
              return null;
            }, [dateId]);

            if (questions.isEmpty) {
              return Center(
                child: Text(
                  context.l10n.dwNoQuestionsAvail,
                  style: DwText.dm(
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              );
            }

            final q = questions[index.value.clamp(0, questions.length - 1)];
            final total = questions.length;
            final current = index.value.clamp(0, questions.length - 1) + 1;
            final isBookmarked = bookmarks.value[q.uuid] ?? false;
            final isQueued = queued.value[q.uuid] ?? false;

            return ReviewBody(
              title: context.l10n.dwStaticWarRevise,
              showRevisionBadge: false,
              progressRight: dateId,
              question: q,
              current: current,
              total: total,
              isBookmarked: isBookmarked,
              isQueued: isQueued,
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
                    context.go('/daily-war/history/$dateId');
                  }
                } else {
                  index.value = index.value + 1;
                }
              },
              uiLanguage: uiLanguage.value,
              onLanguageChanged: (lang) {
                uiLanguage.value = lang;
                unawaited(switchAppLanguage(context, ref, lang));
              },
            );
          },
        ),
      ),
    );
  }
}
