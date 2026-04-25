import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:uuid/uuid.dart';

import 'package:upsc_wars/core/analytics/activation_milestones.dart';
import 'package:upsc_wars/core/providers/analytics_provider.dart';
import 'package:upsc_wars/core/providers/prefs_provider.dart';
import 'package:upsc_wars/core/domain/entities/test_question_share_map.dart';
import 'package:upsc_wars/core/providers/catalog_providers.dart';
import 'package:upsc_wars/core/providers/user_database_provider.dart';
import 'package:upsc_wars/core/router/app_router.dart';
import 'package:upsc_wars/shared/widgets/app_toast.dart';

import 'share_link_kind.dart';
import 'share_link_parser.dart';
import 'share_link_url_builder.dart';
import 'shared_session_firestore.dart';

void showShareLinkMessage(String message) {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null || !ctx.mounted) return;
  AppToast.showText(ctx, message);
}

/// Imports a fixed-id session from [payload] and navigates to the test engine.
///
/// The user always chooses **Normal** (`exam`) or **Learning** on a bottom sheet
/// (share payloads do not include mode).
///
/// [payload.questionIds] may be empty: then questions are resolved from Firestore
/// `session/{shareId}` field `uuids`.
Future<void> openShareLinkPayload({
  required WidgetRef ref,
  required GoRouter router,
  required ShareLinkPayload payload,
}) async {
  debugPrint(
    '[share-link] openShareLinkPayload kind=${payload.kind} shareId=${payload.shareId} '
    'ids=${payload.questionIds.length} subject=${payload.subject} topic=${payload.topic}',
  );
  try {
    var questionIds = payload.questionIds;
    var subject = payload.subject;
    var topic = payload.topic;
    var sharedBy = 'A friend';

    if (questionIds.isEmpty) {
      debugPrint('[share-link] resolving questions from Firestore shareId=${payload.shareId}');
      final repo = SharedSessionFirestoreRepository();
      final doc = await repo.fetch(payload.shareId);
      questionIds = doc.orderedQuestionUuids;
      subject ??= doc.subject;
      topic ??= doc.topic;
      sharedBy = doc.sharedBy ?? 'A friend';
      debugPrint(
        '[share-link] firestore resolved count=${questionIds.length} subject=$subject topic=$topic sharedBy=$sharedBy',
      );
      if (payload.kind == ShareLinkKind.question && questionIds.length != 1) {
        showShareLinkMessage('Invalid shared question.');
        return;
      }
    }

    if (subject == null || subject.isEmpty) {
      debugPrint('[share-link] resolving subject from local db');
      final q = await ref
          .read(userDatabaseProvider)
          .questionsDao
          .getByUuid(questionIds.first);
      subject = q?.subject ?? 'Misc';
      topic ??= q?.topic;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = '/share-launch/${payload.shareId}';
      debugPrint('[share-link] navigating to $loc');
      try {
        router.go(loc);
      } on GoException catch (e, st) {
        debugPrint('[share-link] GoException while navigating to $loc: $e');
        debugPrintStack(stackTrace: st);
        // Router may not be ready yet (cold start). Retry once after a short delay.
        unawaited(() async {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          try {
            debugPrint('[share-link] retry navigating to $loc');
            router.go(loc);
          } catch (e2, st2) {
            debugPrint('[share-link] retry failed for $loc: $e2');
            debugPrintStack(stackTrace: st2);
            showShareLinkMessage(
              'Could not open link. Please try again.',
            );
          }
        }());
      } catch (e, st) {
        debugPrint('[share-link] Unexpected navigation error to $loc: $e');
        debugPrintStack(stackTrace: st);
        showShareLinkMessage('Could not open link.');
      }
    });
  } on StateError catch (e) {
    debugPrint('[share-link] StateError: ${e.message}');
    showShareLinkMessage(e.message);
  } catch (_) {
    debugPrint('[share-link] Unknown error opening shared questions.');
    showShareLinkMessage('Could not open shared questions.');
  }
}

/// Opens a share [uri] after bootstrap; no-op if not a share link.
Future<void> openShareUriIfApplicable({
  required WidgetRef ref,
  required GoRouter router,
  required Uri uri,
}) async {
  debugPrint('[share-link] incoming uri=$uri');
  final parsed = parseShareLinkUri(uri);
  debugPrint('[share-link] parsed payload=$parsed');
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
  final uri = await createShareLinkForSession(ref: ref, sessionId: sessionId);
  if (uri == null) return;

  await SharePlus.instance.share(ShareParams(uri: uri));
}

/// Creates a share link for current session: writes Firestore `session/{shareId}`
/// returns the HTTPS [Uri].
Future<Uri?> createShareLinkForSession({
  required WidgetRef ref,
  required String sessionId,
}) async {
  final sharer = FirebaseAuth.instance.currentUser;
  final sharedBy = (sharer?.displayName ?? sharer?.email ?? 'A friend').trim();

  final load = await ref.read(loadSessionUseCaseProvider.future);
  final active = await load.execute(sessionId);
  final sorted = [...active.questions]
    ..sort((a, b) => a.position.compareTo(b.position));
  if (sorted.isEmpty) {
    showShareLinkMessage('No questions to share.');
    return null;
  }

  final kind = active.analyticsFeatureKey == 'mcq_battle'
      ? ShareLinkKind.battle
      : (sorted.length == 1 ? ShareLinkKind.question : ShareLinkKind.test);

  final shareId = _shareUuid.v4();
  final maps = sorted.map(testQuestionToShareMap).toList();
  final subjectForShare = active.subject.trim().isEmpty
      ? 'Misc'
      : active.subject.trim();

  try {
    final fs = SharedSessionFirestoreRepository();
    await fs.uploadSession(
      shareId: shareId,
      kind: kind,
      subject: subjectForShare,
      topic: active.topic,
      sharedBy: sharedBy.isEmpty ? 'A friend' : sharedBy,
      questionMaps: maps,
    );
  } on FirebaseException catch (e, st) {
    debugPrint(
      'createShareLinkForSession FirebaseException: ${e.code} ${e.message}',
    );
    debugPrintStack(stackTrace: st);
    final msg = switch (e.code) {
      'permission-denied' =>
        'Share upload blocked (permission). Deploy latest firestore.rules and sign in.',
      'unavailable' => 'Network issue. Try again when online.',
      _ => 'Could not upload share (${e.code}).',
    };
    showShareLinkMessage(msg);
    return null;
  } catch (e, st) {
    debugPrint('createShareLinkForSession: $e');
    debugPrintStack(stackTrace: st);
    showShareLinkMessage('Could not upload share: $e');
    return null;
  }

  final uri = buildShareHttpsUri(
    kind: kind,
    shareId: shareId,
    subject: active.subject,
    topic: active.topic,
  );

  if (kDebugMode) {
    debugPrint('createShareLinkForSession: generated $kind shareId=$shareId');
  }

  unawaited(() async {
    final prefs = await ref.read(prefsServiceProvider.future);
    await logActivationMilestoneForServices(
      ref.read(analyticsServiceProvider),
      prefs,
      id: ActivationMilestones.firstScorecardShare,
    );
  }());

  return uri;
}

/// Creates a share link for a specific question in a session.
Future<Uri?> createShareLinkForQuestion({
  required WidgetRef ref,
  required String sessionId,
  required String questionUuid,
}) async {
  final sharer = FirebaseAuth.instance.currentUser;
  final sharedBy = (sharer?.displayName ?? sharer?.email ?? 'A friend').trim();

  final load = await ref.read(loadSessionUseCaseProvider.future);
  final active = await load.execute(sessionId);
  final question = active.questions.cast<TestQuestion?>().firstWhere(
    (q) => q?.uuid == questionUuid,
    orElse: () => null,
  );

  if (question == null) {
    showShareLinkMessage('Question not found in session.');
    return null;
  }

  final kind = ShareLinkKind.question;
  final shareId = _shareUuid.v4();
  final maps = [testQuestionToShareMap(question)];
  final subjectForShare = active.subject.trim().isEmpty
      ? 'Misc'
      : active.subject.trim();

  try {
    final fs = SharedSessionFirestoreRepository();
    await fs.uploadSession(
      shareId: shareId,
      kind: kind,
      subject: subjectForShare,
      topic: active.topic,
      sharedBy: sharedBy.isEmpty ? 'A friend' : sharedBy,
      questionMaps: maps,
    );
  } on FirebaseException catch (e, st) {
    debugPrint(
      'createShareLinkForQuestion FirebaseException: ${e.code} ${e.message}',
    );
    debugPrintStack(stackTrace: st);
    final msg = switch (e.code) {
      'permission-denied' =>
        'Share upload blocked (permission). Deploy latest firestore.rules and sign in.',
      'unavailable' => 'Network issue. Try again when online.',
      _ => 'Could not upload share (${e.code}).',
    };
    showShareLinkMessage(msg);
    return null;
  } catch (e, st) {
    debugPrint('createShareLinkForQuestion: $e');
    debugPrintStack(stackTrace: st);
    showShareLinkMessage('Could not upload share: $e');
    return null;
  }

  final uri = buildShareHttpsUri(
    kind: kind,
    shareId: shareId,
    subject: active.subject,
    topic: active.topic,
  );

  return uri;
}

/// Creates a share link for a specific TestQuestion object (no session needed).
Future<Uri?> createShareLinkForTestQuestion({
  required WidgetRef ref,
  required TestQuestion question,
}) async {
  final sharer = FirebaseAuth.instance.currentUser;
  final sharedBy = (sharer?.displayName ?? sharer?.email ?? 'A friend').trim();

  final kind = ShareLinkKind.question;
  final shareId = _shareUuid.v4();
  final maps = [testQuestionToShareMap(question)];
  final subjectForShare = question.subject.trim().isEmpty
      ? 'Misc'
      : question.subject.trim();

  try {
    final fs = SharedSessionFirestoreRepository();
    await fs.uploadSession(
      shareId: shareId,
      kind: kind,
      subject: subjectForShare,
      topic: question.topic,
      sharedBy: sharedBy.isEmpty ? 'A friend' : sharedBy,
      questionMaps: maps,
    );
  } on FirebaseException catch (e, st) {
    debugPrint(
      'createShareLinkForTestQuestion FirebaseException: ${e.code} ${e.message}',
    );
    debugPrintStack(stackTrace: st);
    final msg = switch (e.code) {
      'permission-denied' =>
        'Share upload blocked (permission). Deploy latest firestore.rules and sign in.',
      'unavailable' => 'Network issue. Try again when online.',
      _ => 'Could not upload share (${e.code}).',
    };
    showShareLinkMessage(msg);
    return null;
  } catch (e, st) {
    debugPrint('createShareLinkForTestQuestion: $e');
    debugPrintStack(stackTrace: st);
    showShareLinkMessage('Could not upload share: $e');
    return null;
  }

  final uri = buildShareHttpsUri(
    kind: kind,
    shareId: shareId,
    subject: question.subject,
    topic: question.topic,
  );

  return uri;
}
