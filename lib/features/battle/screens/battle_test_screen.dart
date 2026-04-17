import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/features/battle/providers/battle_session_provider.dart';
import 'package:upsc_wars/features/battle/widgets/battle_score_header.dart';
import 'package:upsc_wars/shared/widgets/top_snack_bar.dart';

class BattleTestScreen extends ConsumerWidget {
  const BattleTestScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(battleSessionProvider(sessionId));
    final notifier = ref.read(battleSessionProvider(sessionId).notifier);

    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final battle = state.battleSession;
    if (battle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Battle')),
        body: Center(
          child: Text(
            state.errorMessage ?? 'Could not open battle.',
            style: AppTextStyles.body(),
          ),
        ),
      );
    }

    final session = battle.baseSession;
    final q = session.questions[state.currentIndex];
    final playerScore = state.playerScore!;
    final opponentScore = state.opponentScore!;
    final isLast = state.currentIndex == session.questions.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Battle · Q${state.currentIndex + 1}/${session.questions.length}',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BattleScoreHeader(
                playerName: battle.player.displayName,
                opponentName: battle.opponent.displayName,
                playerScore: playerScore,
                opponentScore: opponentScore,
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: _BattleQuestionCard(
                  question: q,
                  selectedOption: q.selectedOption,
                  onSelectOption: notifier.selectOption,
                ),
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  state.errorMessage!,
                  style: AppTextStyles.caption().copyWith(
                    color: AppColors.wrong,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state.currentIndex > 0
                          ? notifier.movePrev
                          : null,
                      child: const Text('Prev'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: isLast
                        ? ElevatedButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () async {
                                    try {
                                      final id = await notifier.submit();
                                      if (context.mounted) {
                                        context.go('/results/$id');
                                      }
                                    } catch (_) {
                                      if (!context.mounted) return;
                                      showTopSnackBar(
                                        context,
                                        content: Text(
                                          'Could not submit battle. Please retry.',
                                          style: AppTextStyles.bodyMd()
                                              .copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                              ),
                                        ),
                                      );
                                    }
                                  },
                            child: const Text('Submit'),
                          )
                        : OutlinedButton(
                            onPressed: notifier.moveNext,
                            child: const Text('Next'),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BattleQuestionCard extends StatelessWidget {
  const _BattleQuestionCard({
    required this.question,
    required this.selectedOption,
    required this.onSelectOption,
  });

  final TestQuestion question;
  final String? selectedOption;
  final Future<void> Function(String option) onSelectOption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.displayText,
            style: AppTextStyles.question().copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final option in const ['a', 'b', 'c', 'd']) ...[
            _BattleOptionTile(
              option: option,
              text: _optionText(question, option),
              selected: selectedOption == option,
              onTap: selectedOption == null
                  ? () => onSelectOption(option)
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  String _optionText(TestQuestion q, String option) {
    switch (option) {
      case 'a':
        return q.optionA;
      case 'b':
        return q.optionB;
      case 'c':
        return q.optionC;
      default:
        return q.optionD;
    }
  }
}

class _BattleOptionTile extends StatelessWidget {
  const _BattleOptionTile({
    required this.option,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String option;
  final String text;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              option.toUpperCase(),
              style: AppTextStyles.label().copyWith(color: scheme.onSurface),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.option().copyWith(color: scheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
