import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/core/constants/timed_exam_debug_constants.dart';
import 'package:upsc_wars/core/domain/entities/session_config.dart';
import 'package:upsc_wars/core/providers/catalog_providers.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/features/battle/data/battle_firestore_paths.dart';
import 'package:upsc_wars/features/battle/data/battle_match_firestore_service.dart';
import 'package:upsc_wars/features/home/providers/auth_providers.dart';

/// Joiner entry: deep link / manual route with [sessionId] from host invite.
class BattleJoinScreen extends ConsumerStatefulWidget {
  const BattleJoinScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<BattleJoinScreen> createState() => _BattleJoinScreenState();
}

class _BattleJoinScreenState extends ConsumerState<BattleJoinScreen> {
  String? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final user = ref.read(authStateChangesProvider).asData?.value;
    final guestEmail = (user?.email ?? '').toLowerCase().trim();
    if (guestEmail.isEmpty) {
      setState(() {
        _busy = false;
        _error = 'Sign in to join this battle.';
      });
      return;
    }

    try {
      final snap = await BattleFirestorePaths.matchDoc(widget.sessionId).get();
      if (!snap.exists) {
        setState(() {
          _busy = false;
          _error = 'This battle was not found. It may have expired.';
        });
        return;
      }
      final d = snap.data()!;
      if (d['battle_mode'] != BattleMatchFirestoreService.battleModeHuman) {
        setState(() {
          _busy = false;
          _error = 'This link is not for a player-vs-player battle.';
        });
        return;
      }
      final expectedGuest = (d['guest_email'] as String?)?.toLowerCase() ?? '';
      if (expectedGuest.isEmpty || guestEmail != expectedGuest) {
        setState(() {
          _busy = false;
          _error = 'This invite was sent to a different account.';
        });
        return;
      }

      final lets = d['lets_start_game'];
      final started = lets is bool && lets;
      if (started) {
        setState(() {
          _busy = false;
          _error =
              'This battle is no longer accepting joins. It may have already started.';
        });
        return;
      }

      final uuidsRaw = d['question_uuids'];
      if (uuidsRaw is! List || uuidsRaw.isEmpty) {
        setState(() {
          _busy = false;
          _error = 'Battle data is incomplete.';
        });
        return;
      }
      final uuids = uuidsRaw.map((e) => e.toString()).toList();
      final subject = (d['subject'] as String?) ?? 'Misc';
      final language = await ref.read(appLanguageProvider.future);

      final importUc = await ref.read(createSessionUseCaseProvider.future);
      await importUc.importSharedBattle(
        sessionId: widget.sessionId,
        config: SessionConfig(
          subject: subject,
          mode: 'exam',
          questionCount: uuids.length,
          isTimed: true,
          timeLimitSecs: uuids.length * kDebugSecondsPerQuestion,
          language: language,
          specificQuestionUuids: uuids,
        ),
      );

      const svc = BattleMatchFirestoreService();
      await svc.mergeGuestProfile(
        sessionId: widget.sessionId,
        guestEmail: guestEmail,
        displayName: user?.displayName ?? 'You',
        photoUrl: user?.photoURL,
      );

      await svc.signalGuestJoinedAndReady(widget.sessionId);

      final hostName = (d['host_display_name'] as String?)?.trim();
      if (!mounted) return;
      final guestPhoto = user?.photoURL?.trim();
      context.go(
        '/battle/wait/${widget.sessionId}',
        extra: {
          'playerName': user?.displayName ?? 'You',
          'opponentName':
              (hostName != null && hostName.isNotEmpty) ? hostName : 'Opponent',
          if (guestPhoto != null && guestPhoto.isNotEmpty)
            'playerPhotoUrl': guestPhoto,
        },
      );
    } on FirebaseException catch (e) {
      setState(() {
        _busy = false;
        _error = e.message ?? 'Could not join battle.';
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Join battle')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _busy
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error ?? 'Something went wrong.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd().copyWith(color: scheme.error),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Home'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
