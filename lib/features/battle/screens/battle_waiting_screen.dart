import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';

class BattleWaitingScreen extends StatefulWidget {
  const BattleWaitingScreen({
    super.key,
    required this.sessionId,
    required this.playerName,
    required this.opponentName,
  });

  final String sessionId;
  final String playerName;
  final String opponentName;

  @override
  State<BattleWaitingScreen> createState() => _BattleWaitingScreenState();
}

class _BattleWaitingScreenState extends State<BattleWaitingScreen> {
  int _secondsLeft = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Random Connect')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text(
              'Players Joined',
              style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.lg),
            _JoinedTile(name: widget.playerName, subtitle: 'You'),
            const SizedBox(height: AppSpacing.sm),
            _JoinedTile(name: widget.opponentName, subtitle: 'Joined'),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Starting battle in $_secondsLeft...',
              style: AppTextStyles.body().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _JoinedTile extends StatelessWidget {
  const _JoinedTile({required this.name, required this.subtitle});
  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.person)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.label().copyWith(color: scheme.onSurface),
            ),
          ),
          Text(
            subtitle,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
