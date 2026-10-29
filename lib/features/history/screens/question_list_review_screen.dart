import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/core/providers/app_language_helpers.dart';
import 'package:upsc_wars/core/providers/catalog_providers.dart';
import 'package:upsc_wars/core/providers/user_database_provider.dart';
import 'package:upsc_wars/features/history/providers/review_session_provider.dart';
import 'package:upsc_wars/features/history/screens/session_review_screen.dart';
import '../../../l10n/l10n.dart';

/// Route `extra` for [QuestionListReviewScreen] — session-review UI over a
/// fixed list (no live test session).
class QuestionListReviewArgs {
  const QuestionListReviewArgs({
    required this.questions,
    this.title,
    this.progressRight,
  });

  final List<TestQuestion> questions;
  final String? title;
  final String? progressRight;
}

/// Question review pager for an in-memory list (insight Revise, etc.).
class QuestionListReviewScreen extends HookConsumerWidget {
  const QuestionListReviewScreen({super.key, required this.args});

  final QuestionListReviewArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = args.questions;
    if (questions.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: TextButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/'),
              child: Text(context.l10n.commonDone),
            ),
          ),
        ),
      );
    }

    final index = useState(0);
    final preferredLanguage = watchAppLanguage(ref);
    final uiLanguage = useState(preferredLanguage);
    final bookmarks = useState<Map<String, bool>>({});
    final queue = useState<Map<String, bool>>({});

    useEffect(() {
      unawaited(() async {
        final repo = await ref.read(testEngineRepositoryProvider.future);
        final userDb = ref.read(userDatabaseProvider);
        final bm = <String, bool>{};
        final queued = <String, bool>{};
        for (final q in questions) {
          bm[q.uuid] = await repo.isBookmarked(q.uuid);
          final item = await userDb.revisionQueueDao
              .getRevisionQueueItemByQuestionUuid(q.uuid);
          queued[q.uuid] = item != null;
        }
        if (!context.mounted) return;
        bookmarks.value = bm;
        queue.value = queued;
      }());
      return null;
    }, [questions]);

    final q = questions[index.value.clamp(0, questions.length - 1)];
    final total = questions.length;
    final current = index.value.clamp(0, questions.length - 1) + 1;
    final isBookmarked = bookmarks.value[q.uuid] ?? false;
    final isQueued = queue.value[q.uuid] ?? false;

    return Scaffold(
      body: SafeArea(
        child: ReviewBody(
          title: args.title ?? context.l10n.srTitle,
          showRevisionBadge: false,
          progressRight:
              args.progressRight ??
              context.l10n.reviewCorrectWrong(
                questions.where((e) => e.status == 'correct').length,
                questions.where((e) => e.status == 'wrong').length,
              ),
          question: q,
          current: current,
          total: total,
          isBookmarked: isBookmarked,
          isQueued: isQueued,
          confidenceSessionId: 'insight_revise',
          analyticsSource: 'insight_revise',
          onToggleBookmark: () async {
            final repo = await ref.read(testEngineRepositoryProvider.future);
            if (isBookmarked) {
              await repo.removeBookmark(q.uuid);
            } else {
              await repo.addBookmark(q.uuid);
            }
            bookmarks.value = {...bookmarks.value, q.uuid: !isBookmarked};
            queue.value = {...queue.value, q.uuid: true};
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
          onAddToRevision: () async {
            if (queue.value[q.uuid] == true) return;
            final userDb = ref.read(userDatabaseProvider);
            await userDb.revisionQueueDao.add(
              id: reviewSessionUuid.v4(),
              questionUuid: q.uuid,
              dateAddedToQueue: DateTime.now(),
            );
            queue.value = {...queue.value, q.uuid: true};
          },
          uiLanguage: uiLanguage.value,
          onLanguageChanged: (lang) {
            uiLanguage.value = lang;
            unawaited(switchAppLanguage(context, ref, lang));
          },
        ),
      ),
    );
  }
}
