import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/core/constants/app_constants.dart';
import 'package:upsc_wars/core/presentation/user_display_name.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/features/battle/data/battle_firestore_paths.dart';
import 'package:upsc_wars/features/battle/data/battle_match_firestore_service.dart';
import 'package:upsc_wars/features/battle/domain/battle_monogram_palette.dart';
import 'package:upsc_wars/features/home/providers/auth_providers.dart';

/// Human-readable room-style id (stable for a given session UUID).
String battleRoomDisplayId(String sessionId) {
  final hex = sessionId.replaceAll('-', '');
  if (hex.length < 10) return sessionId;
  try {
    final slice = hex.length >= 12 ? hex.substring(0, 12) : hex;
    final v = BigInt.parse(slice, radix: 16);
    final n = (v % BigInt.from(1000000000000)).toInt();
    final s = n.toString().padLeft(12, '0');
    return '${s.substring(0, 4)}-${s.substring(4, 7)}-${s.substring(7)}';
  } catch (_) {
    return sessionId.length > 18 ? '${sessionId.substring(0, 8)}…' : sessionId;
  }
}

/// After config (bot or human) or after guest join: bot uses a short countdown;
/// human uses a lobby until [lets_start_game] (host taps Start).
class BattleWaitingScreen extends ConsumerStatefulWidget {
  const BattleWaitingScreen({
    super.key,
    required this.sessionId,
    required this.playerName,
    required this.opponentName,
    this.playerPhotoUrl,
    this.opponentPhotoUrl,
  });

  final String sessionId;
  final String playerName;
  final String opponentName;
  final String? playerPhotoUrl;
  final String? opponentPhotoUrl;

  @override
  ConsumerState<BattleWaitingScreen> createState() =>
      _BattleWaitingScreenState();
}

enum _WaitUiMode { loading, botCountdown, humanLobby }

class _BattleWaitingScreenState extends ConsumerState<BattleWaitingScreen> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _matchSub;
  _WaitUiMode _mode = _WaitUiMode.loading;
  Map<String, dynamic>? _match;
  bool _navigatedToBattle = false;
  bool _startingBattle = false;

  @override
  void initState() {
    super.initState();
    _matchSub = BattleFirestorePaths.matchDoc(
      widget.sessionId,
    ).snapshots().listen(_onMatchSnapshot);
  }

  void _onMatchSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    if (!snap.exists) {
      setState(() {
        _mode = _WaitUiMode.botCountdown;
        _match = null;
      });
      return;
    }
    final d = snap.data()!;
    final mode = d['battle_mode'] as String?;
    if (mode == BattleMatchFirestoreService.battleModeHuman) {
      final lets = d['lets_start_game'] == true;
      if (lets && !_navigatedToBattle) {
        _navigatedToBattle = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.go('/battle/${widget.sessionId}');
          }
        });
      }
      setState(() {
        _mode = _WaitUiMode.humanLobby;
        _match = d;
      });
    } else {
      setState(() {
        _mode = _WaitUiMode.botCountdown;
        _match = null;
      });
    }
  }

  @override
  void dispose() {
    _matchSub?.cancel();
    super.dispose();
  }

  String _initialLetter(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t[0].toUpperCase();
  }

  String _shortName(String name, {int maxChars = 9}) {
    final t = name.trim();
    if (t.length <= maxChars) return t;
    return '${t.substring(0, maxChars - 1)}…';
  }

  void _leaveMatchScreen() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _onHostStartBattle() async {
    if (_startingBattle) return;
    setState(() => _startingBattle = true);
    try {
      const svc = BattleMatchFirestoreService();
      await svc.signalHostStartedBattle(widget.sessionId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start battle. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _startingBattle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _leaveMatchScreen();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceSecondaryDark
            : AppColors.surfaceSecondaryLight,
        appBar: AppBar(
          title: const Text('Match'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _leaveMatchScreen,
          ),
        ),
        body: switch (_mode) {
          _WaitUiMode.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          _WaitUiMode.botCountdown => _BattleWaitBotCountdown(
            sessionId: widget.sessionId,
            playerName: widget.playerName,
            opponentName: widget.opponentName,
            playerPhotoUrl: widget.playerPhotoUrl,
          ),
          _WaitUiMode.humanLobby => _HumanLobbyBody(
            sessionId: widget.sessionId,
            match: _match!,
            playerName: widget.playerName,
            opponentName: widget.opponentName,
            playerPhotoUrl: widget.playerPhotoUrl,
            opponentPhotoUrl: widget.opponentPhotoUrl,
            authEmail:
                (ref.watch(authStateChangesProvider).asData?.value?.email ?? '')
                    .toLowerCase()
                    .trim(),
            onHostStartBattle: _onHostStartBattle,
            startingBattle: _startingBattle,
            initialLetter: _initialLetter,
            shortName: _shortName,
          ),
        },
      ),
    );
  }
}

/// Bot / no match doc: original short countdown then open battle test.
class _BattleWaitBotCountdown extends StatefulWidget {
  const _BattleWaitBotCountdown({
    required this.sessionId,
    required this.playerName,
    required this.opponentName,
    this.playerPhotoUrl,
  });

  final String sessionId;
  final String playerName;
  final String opponentName;
  final String? playerPhotoUrl;

  @override
  State<_BattleWaitBotCountdown> createState() =>
      _BattleWaitBotCountdownState();
}

class _BattleWaitBotCountdownState extends State<_BattleWaitBotCountdown>
    with SingleTickerProviderStateMixin {
  static const _countdownSeconds = 4;
  int _secondsLeft = _countdownSeconds;
  Timer? _timer;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        if (mounted) {
          context.go('/battle/${widget.sessionId}');
        }
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  String _initialLetter(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t[0].toUpperCase();
  }

  String _shortName(String name, {int maxChars = 9}) {
    final t = name.trim();
    if (t.length <= maxChars) return t;
    return '${t.substring(0, maxChars - 1)}…';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final battleId = battleRoomDisplayId(widget.sessionId);
    final idColor = isDark ? AppColors.warningTextDark : AppColors.warning;
    final hostBg = battleMatchMonogramBackground(widget.sessionId, 'host');
    final hostFg = battleMatchMonogramForeground(hostBg);
    final oppBg = battleMatchMonogramBackground(widget.sessionId, 'opponent');
    final oppFg = battleMatchMonogramForeground(oppBg);
    final youBg = battleMatchMonogramBackground(widget.sessionId, 'you');
    final youFg = battleMatchMonogramForeground(youBg);

    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  elevation: 0,
                  color: scheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    side: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        _HostAvatar(
                          photoUrl: widget.playerPhotoUrl,
                          fallbackLetter: _initialLetter(widget.playerName),
                          monogramBackground: hostBg,
                          monogramForeground: hostFg,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          kViewerSelfDisplayLabel,
                          style: AppTextStyles.h2().copyWith(
                            color: scheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Battle ID',
                          style: AppTextStyles.labelSm().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        SelectableText(
                          battleId,
                          style: AppTextStyles.h1().copyWith(
                            color: idColor,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Divider(
                          height: 1,
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          '2 joined',
                          style: AppTextStyles.label().copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _JoinedParticipant(
                              letter: _initialLetter(widget.opponentName),
                              label: _shortName(widget.opponentName),
                              scheme: scheme,
                              monogramBackground: oppBg,
                              monogramForeground: oppFg,
                              greyed: false,
                            ),
                            _JoinedParticipant(
                              letter: _initialLetter(widget.playerName),
                              label: 'You',
                              scheme: scheme,
                              monogramBackground: youBg,
                              monogramForeground: youFg,
                              greyed: false,
                              avatar: _HostAvatar(
                                radius: 22,
                                photoUrl: widget.playerPhotoUrl,
                                fallbackLetter: _initialLetter(
                                  widget.playerName,
                                ),
                                monogramBackground: youBg,
                                monogramForeground: youFg,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final o = 0.42 + _pulse.value * 0.48;
                return Opacity(opacity: o, child: child);
              },
              child: Text(
                'Please wait… battle is starting in a few seconds.',
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HumanLobbyBody extends StatelessWidget {
  const _HumanLobbyBody({
    required this.sessionId,
    required this.match,
    required this.playerName,
    required this.opponentName,
    required this.playerPhotoUrl,
    required this.opponentPhotoUrl,
    required this.authEmail,
    required this.onHostStartBattle,
    required this.startingBattle,
    required this.initialLetter,
    required this.shortName,
  });

  final String sessionId;
  final Map<String, dynamic> match;
  final String playerName;
  final String opponentName;
  final String? playerPhotoUrl;
  final String? opponentPhotoUrl;
  final String authEmail;
  final VoidCallback onHostStartBattle;
  final bool startingBattle;
  final String Function(String) initialLetter;
  final String Function(String) shortName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final battleId = battleRoomDisplayId(sessionId);
    final idColor = isDark ? AppColors.warningTextDark : AppColors.warning;

    final hostEmail = (match['host_email'] as String?)?.toLowerCase() ?? '';
    final isHost = authEmail.isNotEmpty && authEmail == hostEmail;
    final guestReady =
        match[BattleMatchFirestoreService.fieldGuestReady] == true;
    final letsStart = match['lets_start_game'] == true;

    final opponentGreyed = isHost ? !guestReady : !letsStart;

    final hostBg = battleMatchMonogramBackground(sessionId, 'host');
    final hostFg = battleMatchMonogramForeground(hostBg);
    final oppBg = battleMatchMonogramBackground(sessionId, 'opponent');
    final oppFg = battleMatchMonogramForeground(oppBg);
    final youBg = battleMatchMonogramBackground(sessionId, 'you');
    final youFg = battleMatchMonogramForeground(youBg);

    final statusLine = isHost
        ? (guestReady
              ? 'Opponent joined. Start the battle when you are ready.'
              : 'Waiting for your opponent to open the invite and join.')
        : (letsStart
              ? 'Starting battle…'
              : 'Waiting for the host to start the battle.');

    final opponentAvatar =
        (opponentPhotoUrl != null && opponentPhotoUrl!.trim().isNotEmpty)
        ? CircleAvatar(
            radius: 22,
            backgroundColor: scheme.primaryContainer,
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: opponentPhotoUrl!.trim(),
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                memCacheWidth: (44 * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                errorWidget: (_, _, _) => CircleAvatar(
                  radius: 22,
                  backgroundColor: oppBg,
                  foregroundColor: oppFg,
                  child: Text(
                    initialLetter(opponentName),
                    style: AppTextStyles.label().copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          )
        : CircleAvatar(
            radius: 22,
            backgroundColor: oppBg,
            foregroundColor: oppFg,
            child: Text(
              initialLetter(opponentName),
              style: AppTextStyles.label().copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          );

    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  elevation: 0,
                  color: scheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    side: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        _HostAvatar(
                          photoUrl: playerPhotoUrl,
                          fallbackLetter: initialLetter(playerName),
                          monogramBackground: hostBg,
                          monogramForeground: hostFg,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          kViewerSelfDisplayLabel,
                          style: AppTextStyles.h2().copyWith(
                            color: scheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Battle ID',
                          style: AppTextStyles.labelSm().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        SelectableText(
                          battleId,
                          style: AppTextStyles.h1().copyWith(
                            color: idColor,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Divider(
                          height: 1,
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          guestReady
                              ? 'Opponent in lobby'
                              : 'Waiting for opponent',
                          style: AppTextStyles.label().copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _JoinedParticipant(
                              letter: initialLetter(opponentName),
                              label: shortName(opponentName),
                              scheme: scheme,
                              monogramBackground: oppBg,
                              monogramForeground: oppFg,
                              greyed: opponentGreyed,
                              avatar: opponentAvatar,
                            ),
                            _JoinedParticipant(
                              letter: initialLetter(playerName),
                              label: 'You',
                              scheme: scheme,
                              monogramBackground: youBg,
                              monogramForeground: youFg,
                              greyed: false,
                              avatar: _HostAvatar(
                                radius: 22,
                                photoUrl: playerPhotoUrl,
                                fallbackLetter: initialLetter(playerName),
                                monogramBackground: youBg,
                                monogramForeground: youFg,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  statusLine,
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (isHost) ...[
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: (guestReady && !letsStart && !startingBattle)
                        ? onHostStartBattle
                        : null,
                    child: startingBattle
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Start battle'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HostAvatar extends StatelessWidget {
  const _HostAvatar({
    required this.fallbackLetter,
    this.photoUrl,
    this.radius = 36,
    required this.monogramBackground,
    required this.monogramForeground,
  });

  final String? photoUrl;
  final String fallbackLetter;
  final double radius;
  final Color monogramBackground;
  final Color monogramForeground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = AppConstants.profileImageUrlOrDefault(photoUrl);
    final side = radius * 2;
    final cachePx = (side * MediaQuery.devicePixelRatioOf(context)).round();
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: side,
          height: side,
          fit: BoxFit.cover,
          memCacheWidth: cachePx,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          errorWidget: (_, _, _) => _fallbackLetter(letter: fallbackLetter),
        ),
      ),
    );
  }

  Widget _fallbackLetter({required String letter}) {
    return Center(
      child: Text(
        letter,
        style: AppTextStyles.h2().copyWith(
          color: monogramForeground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _JoinedParticipant extends StatelessWidget {
  const _JoinedParticipant({
    required this.letter,
    required this.label,
    required this.scheme,
    this.avatar,
    required this.monogramBackground,
    required this.monogramForeground,
    this.greyed = false,
  });

  final String letter;
  final String label;
  final ColorScheme scheme;
  final Widget? avatar;
  final Color monogramBackground;
  final Color monogramForeground;
  final bool greyed;

  static const _greyscale = <double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  @override
  Widget build(BuildContext context) {
    final raw =
        avatar ??
        CircleAvatar(
          radius: 22,
          backgroundColor: monogramBackground,
          foregroundColor: monogramForeground,
          child: Text(
            letter,
            style: AppTextStyles.label().copyWith(fontWeight: FontWeight.w700),
          ),
        );

    final child = greyed
        ? ColorFiltered(
            colorFilter: const ColorFilter.matrix(_greyscale),
            child: Opacity(opacity: 0.55, child: raw),
          )
        : raw;

    return Expanded(
      child: Column(
        children: [
          child,
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
