import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import 'package:upsc_wars/core/domain/entities/session_config.dart';
import 'package:upsc_wars/core/domain/entities/test_question_share_map.dart';
import 'package:upsc_wars/core/providers/catalog_providers.dart';
import 'package:upsc_wars/core/providers/user_database_provider.dart';
import 'package:upsc_wars/core/router/app_router.dart';

import 'share_link_kind.dart';
import 'share_link_parser.dart';
import 'share_link_url_builder.dart';
import 'shared_session_firestore.dart';

String? _analyticsKeyForKind(ShareLinkKind kind) {
  return switch (kind) {
    ShareLinkKind.battle => 'share_deep_link_battle',
    ShareLinkKind.test => 'share_deep_link_test',
    ShareLinkKind.question => 'share_deep_link_question',
  };
}

void showShareLinkMessage(String message) {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null || !ctx.mounted) return;
  ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
    SnackBar(content: Text(message)),
  );
}

/// Imports a fixed-id learning session from [payload] and navigates to the test engine.
///
/// [payload.questionIds] may be empty: then questions are resolved from Firestore
/// `session/{shareId}` field `uuids`.
Future<void> openShareLinkPayload({
  required WidgetRef ref,
  required GoRouter router,
  required ShareLinkPayload payload,
}) async {
  try {
    var questionIds = payload.questionIds;
    var subject = payload.subject;
    var topic = payload.topic;

    if (questionIds.isEmpty) {
      final repo = SharedSessionFirestoreRepository();
      final doc = await repo.fetch(payload.shareId);
      questionIds = doc.orderedQuestionUuids;
      subject ??= doc.subject;
      topic ??= doc.topic;
      if (payload.kind == ShareLinkKind.question && questionIds.length != 1) {
        showShareLinkMessage('Invalid shared question.');
        return;
      }
    }

    final uc = await ref.read(createSessionUseCaseProvider.future);
    final lang = await ref.read(appLanguageProvider.future);

    if (subject == null || subject.isEmpty) {
      final q = await ref
          .read(userDatabaseProvider)
          .questionsDao
          .getByUuid(questionIds.first);
      subject = q?.subject ?? 'Misc';
      topic ??= q?.topic;
    }

    final config = SessionConfig(
      subject: subject,
      topic: topic,
      mode: 'learning',
      questionCount: questionIds.length,
      isTimed: true,
      timeLimitSecs: 60,
      language: lang,
      specificQuestionUuids: questionIds,
      analyticsFeatureKey: _analyticsKeyForKind(payload.kind),
    );

    await uc.importSharedBattle(sessionId: payload.shareId, config: config);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.go('/test/${payload.shareId}');
    });
  } on StateError catch (e) {
    showShareLinkMessage(e.message);
  } catch (_) {
    showShareLinkMessage('Could not open shared questions.');
  }
}

/// Opens a share [uri] after bootstrap; no-op if not a share link.
Future<void> openShareUriIfApplicable({
  required WidgetRef ref,
  required GoRouter router,
  required Uri uri,
}) async {
  final parsed = parseShareLinkUri(uri);
  if (parsed == null) return;
  await openShareLinkPayload(ref: ref, router: router, payload: parsed);
}

final _shareUuid = Uuid();

/// Share current session: writes Firestore `session/{shareId}` with full question
/// JSON in `uuids`, then opens the system share sheet (short HTTPS link, no `ids`).
Future<void> shareSessionQuestionsLink({
  required WidgetRef ref,
  required String sessionId,
}) async {
  if (FirebaseAuth.instance.currentUser == null) {
    showShareLinkMessage('Sign in to share a question set.');
    return;
  }

  final load = await ref.read(loadSessionUseCaseProvider.future);
  final active = await load.execute(sessionId);
  final sorted = [...active.questions]
    ..sort((a, b) => a.position.compareTo(b.position));
  if (sorted.isEmpty) {
    showShareLinkMessage('No questions to share.');
    return;
  }

  final kind = active.analyticsFeatureKey == 'mcq_battle'
      ? ShareLinkKind.battle
      : (sorted.length == 1 ? ShareLinkKind.question : ShareLinkKind.test);

  final shareId = _shareUuid.v4();
  final maps = sorted.map(testQuestionToShareMap).toList();

  try {
    final fs = SharedSessionFirestoreRepository();
    await fs.uploadSession(
      shareId: shareId,
      kind: kind,
      subject: active.subject,
      topic: active.topic,
      questionMaps: maps,
    );
  } catch (_) {
    showShareLinkMessage('Could not upload share. Check connection and try again.');
    return;
  }

  final uri = buildShareHttpsUri(
    kind: kind,
    shareId: shareId,
    subject: active.subject,
    topic: active.topic,
  );
  await SharePlus.instance.share(ShareParams(uri: uri));
}
