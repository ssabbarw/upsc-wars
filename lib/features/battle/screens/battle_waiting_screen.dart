import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/features/battle/domain/battle_monogram_palette.dart';

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
    return sessionId.length > 18
        ? '${sessionId.substring(0, 8)}…'
        : sessionId;
  }
}

class BattleWaitingScreen extends StatefulWidget {
  const BattleWaitingScreen({
    super.key,
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
  State<BattleWaitingScreen> createState() => _BattleWaitingScreenState();
}

class _BattleWaitingScreenState extends State<BattleWaitingScreen>
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
    final surfaceBg = isDark
        ? AppColors.surfaceSecondaryDark
        : AppColors.surfaceSecondaryLight;
    final battleId = battleRoomDisplayId(widget.sessionId);
    final idColor = isDark ? AppColors.warningTextDark : AppColors.warning;
    final hostBg = battleMatchMonogramBackground(widget.sessionId, 'host');
    final hostFg = battleMatchMonogramForeground(hostBg);
    final oppBg = battleMatchMonogramBackground(widget.sessionId, 'opponent');
    final oppFg = battleMatchMonogramForeground(oppBg);
    final youBg = battleMatchMonogramBackground(widget.sessionId, 'you');
    final youFg = battleMatchMonogramForeground(youBg);

    return Scaffold(
      backgroundColor: surfaceBg,
      appBar: AppBar(
        title: const Text('Match'),
      ),
      body: Column(
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
                            widget.playerName,
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
                              ),
                              _JoinedParticipant(
                                letter: _initialLetter(widget.playerName),
                                label: 'You',
                                scheme: scheme,
                                monogramBackground: youBg,
                                monogramForeground: youFg,
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
                  return Opacity(
                    opacity: o,
                    child: child,
                  );
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
      ),
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
    final url = photoUrl?.trim();
    final side = radius * 2;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: scheme.primaryContainer,
        child: ClipOval(
          child: Image.network(
            url,
            width: side,
            height: side,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallbackLetter(letter: fallbackLetter),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: monogramBackground,
      foregroundColor: monogramForeground,
      child: _fallbackLetter(letter: fallbackLetter),
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
  });

  final String letter;
  final String label;
  final ColorScheme scheme;
  final Widget? avatar;
  final Color monogramBackground;
  final Color monogramForeground;

  @override
  Widget build(BuildContext context) {
    final child =
        avatar ??
        CircleAvatar(
          radius: 22,
          backgroundColor: monogramBackground,
          foregroundColor: monogramForeground,
          child: Text(
            letter,
            style: AppTextStyles.label().copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        );

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
