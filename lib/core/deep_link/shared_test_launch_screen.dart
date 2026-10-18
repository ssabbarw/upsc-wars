import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/core/deep_link/share_link_kind.dart';
import 'package:upsc_wars/core/deep_link/shared_session_firestore.dart';
import 'package:upsc_wars/core/deep_link/shared_test_intro_sheet.dart';
import 'package:upsc_wars/core/domain/entities/session_config.dart';
import 'package:upsc_wars/core/providers/catalog_providers.dart';
import 'package:upsc_wars/core/providers/prefs_provider.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/core/presentation/session_subject_label.dart';
import 'package:upsc_wars/shared/widgets/test_config_bottom_sheet.dart';
import '../../l10n/l10n.dart';

class SharedTestLaunchScreen extends ConsumerStatefulWidget {
  const SharedTestLaunchScreen({super.key, required this.shareId});

  final String shareId;

  @override
  ConsumerState<SharedTestLaunchScreen> createState() =>
      _SharedTestLaunchScreenState();
}

class _SharedTestLaunchScreenState
    extends ConsumerState<SharedTestLaunchScreen> {
  bool _started = false;
  bool _didStartSession = false;
  String? _error;

  static const String _kSingleQuestionTutorialKey =
      'share_single_question_tutorial';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openExistingTestFlow();
    });
  }

  String _analyticsKeyForKind(ShareLinkKind kind) => switch (kind) {
    ShareLinkKind.battle => 'share_deep_link_battle',
    ShareLinkKind.test => 'share_deep_link_test',
    ShareLinkKind.question => 'share_deep_link_question',
  };

  Future<void> _openExistingTestFlow() async {
    try {
      final repo = SharedSessionFirestoreRepository();
      final doc = await repo.fetch(widget.shareId);
      if (!mounted) return;

      final ordered = doc.orderedQuestionUuids;
      if (ordered.isEmpty) {
        setState(() => _error = 'Shared session has no questions.');
        return;
      }

      // Special-case: a shared link with only one question opens directly in an
      // untimed tutorial flow (confidence -> reveal -> explanation), with no
      // config sheet and no submit UI.
      if (ordered.length == 1) {
        final create = await ref.read(createSessionUseCaseProvider.future);
        final lang = await ref.read(appLanguageProvider.future);
        final config = SessionConfig(
          subject: doc.subject,
          topic: doc.topic,
          subTopic: null,
          mode: 'learning',
          questionCount: 1,
          isTimed: false,
          timeLimitSecs: null,
          language: lang,
          specificQuestionUuids: ordered,
          analyticsFeatureKey: _kSingleQuestionTutorialKey,
        );
        final sessionId = await create.execute(config);
        if (!mounted) return;
        _didStartSession = true;
        context.go('/test/$sessionId');
        return;
      }

      final subjectDisplayName = displayNameForSessionSubject(doc.subject);
      final topicDisplayName = doc.topic?.trim().isNotEmpty == true
          ? doc.topic
          : null;
      final sharedByRaw = (doc.sharedBy ?? '').trim();
      final sharedBy = sharedByRaw.isEmpty ? 'a friend' : sharedByRaw;

      final prefs = await ref.read(prefsServiceProvider.future);
      if (!mounted) return;

      List<SharedLeaderboardEntry> leaderboard = const [];
      try {
        leaderboard = await SharedSessionFirestoreRepository()
            .fetchTopLeaderboard(shareId: widget.shareId);
      } catch (_) {
        leaderboard = const [];
      }
      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;
      final fromAuth = (user?.displayName ?? user?.email)?.trim() ?? '';
      final initialName = fromAuth.isNotEmpty
          ? fromAuth
          : (prefs.getString(PrefKeys.shareParticipantNameV1) ?? '');

      final intro = await showSharedTestIntroSheet(
        context: context,
        sharedBy: sharedBy,
        subject: subjectDisplayName,
        topic: topicDisplayName,
        questionCount: ordered.length,
        leaderboard: leaderboard,
        initialName: initialName,
        dismissible: true,
      );
      if (!mounted) return;
      if (intro == null) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
        return;
      }
      await prefs.setString(
        PrefKeys.shareParticipantNameV1,
        intro.participantName,
      );
      if (!mounted) return;

      await showTestConfigBottomSheet(
        context: context,
        args: TestConfigSheetArgs(
          subject: doc.subject,
          topic: doc.topic,
          subTopic: null,
          subjectDisplayName: subjectDisplayName,
          topicDisplayName: topicDisplayName,
          availableQuestionCount: ordered.length,
          topicCountWhenSubjectOnly: 0,
          lockedQuestionCount: ordered.length,
          specificQuestionUuids: ordered,
          fixedQuestionSetLabel: 'Test shared by $sharedBy',
          analyticsFeatureKey: _analyticsKeyForKind(doc.kind),
          onSessionCreated: (sessionId) {
            if (!mounted) return;
            _didStartSession = true;
            unawaited(
              prefs.setString(
                PrefKeys.shareDeepLinkShareIdKey(sessionId),
                widget.shareId,
              ),
            );
            context.go('/test/$sessionId');
          },
        ),
      );

      // If user dismissed the config sheet without starting, go home.
      if (!mounted) return;
      if (_didStartSession) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.stTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.stOhSnap,
                    style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l10n.stExpired,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () => context.go('/'),
                    child: Text(context.l10n.mpGoHome),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.stOpening,
                  style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10n.stPreparing,
                  style: AppTextStyles.bodyMd().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
