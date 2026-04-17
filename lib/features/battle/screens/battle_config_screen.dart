import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:upsc_wars/core/domain/entities/session_config.dart';
import 'package:upsc_wars/core/providers/catalog_providers.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/features/battle/domain/services/battle_name_service.dart';
import 'package:upsc_wars/features/home/providers/auth_providers.dart';

class BattleConfigScreen extends ConsumerStatefulWidget {
  const BattleConfigScreen({super.key});

  @override
  ConsumerState<BattleConfigScreen> createState() => _BattleConfigScreenState();
}

class _BattleConfigScreenState extends ConsumerState<BattleConfigScreen> {
  String? _selectedSubject;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectTestListProvider);
    final scheme = Theme.of(context).colorScheme;
    final me = ref.watch(authStateChangesProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Configure Battle')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _VsHeader(
              me: me?.displayName ?? 'You',
              opponent: BattleNameService.pickFromSeed('random-preview'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Choose subject',
              style: AppTextStyles.label().copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: subjectsAsync.when(
                data: (subjects) => SingleChildScrollView(
                  child: Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final subject in subjects)
                          ChoiceChip(
                            label: Text(subject.displayName),
                            selected: _selectedSubject == subject.subject,
                            onSelected: (_) {
                              setState(
                                () => _selectedSubject = subject.subject,
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, stackTrace) =>
                    const Center(child: Text('Could not load subjects')),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Battle format: 10 MCQs · Timed (${(10 * 72 / 60).round()} min)',
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: _submitting || _selectedSubject == null
                  ? null
                  : () => _startBattle(context, me?.displayName ?? 'You'),
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send Invite'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startBattle(BuildContext context, String playerName) async {
    final subject = _selectedSubject;
    if (subject == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      final uc = await ref.read(createSessionUseCaseProvider.future);
      final language = await ref.read(appLanguageProvider.future);
      final config = SessionConfig(
        subject: subject,
        mode: 'exam',
        questionCount: 10,
        isTimed: true,
        timeLimitSecs: 10 * 72,
        language: language,
      );
      final sessionId = await uc.execute(config);
      final opponentName = BattleNameService.pickFromSeed(sessionId);
      if (!context.mounted) return;
      context.go(
        '/battle/wait/$sessionId',
        extra: {'playerName': playerName, 'opponentName': opponentName},
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _VsHeader extends StatelessWidget {
  const _VsHeader({required this.me, required this.opponent});
  final String me;
  final String opponent;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(height: 6),
                Text(me, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(
            'VS',
            style: AppTextStyles.h3().copyWith(color: scheme.onSurfaceVariant),
          ),
          Expanded(
            child: Column(
              children: [
                const CircleAvatar(child: Icon(Icons.person_outline)),
                const SizedBox(height: 6),
                Text(opponent, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
