import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../community/widgets/qotd_option_letters_row.dart';
import '../domain/fomo_pulse_models.dart';

class FomoPulseQuestionBlock extends StatelessWidget {
  const FomoPulseQuestionBlock({
    super.key,
    required this.question,
    required this.picked,
    required this.onPick,
    this.busy = false,
    this.revealCorrect = false,
  });

  final FomoPulseQuestion question;
  final String? picked;
  final ValueChanged<String> onPick;
  final bool busy;
  final bool revealCorrect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final display = question.displayText.trim();
    final prompt = display.isNotEmpty
        ? display
        : (question.newsTrigger.isNotEmpty
              ? question.newsTrigger
              : 'Answer this Pulse');
    final hasOptionText = question.optionA.trim().isNotEmpty ||
        question.optionB.trim().isNotEmpty ||
        question.optionC.trim().isNotEmpty ||
        question.optionD.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          prompt,
          style: AppTextStyles.body().copyWith(height: 1.4),
        ),
        if (hasOptionText) ...[
          const SizedBox(height: AppSpacing.md),
          _OptionLine(label: 'A', text: question.optionA),
          _OptionLine(label: 'B', text: question.optionB),
          _OptionLine(label: 'C', text: question.optionC),
          _OptionLine(label: 'D', text: question.optionD),
        ],
        const SizedBox(height: AppSpacing.md),
        QotdOptionLettersRow(
          correctOption: revealCorrect ? question.correctOption : 'z',
          picked: picked,
          onPick: onPick,
          busy: busy,
        ),
        if (picked == null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pick an option to submit your answer.',
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _OptionLine extends StatelessWidget {
  const _OptionLine({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label. ', style: AppTextStyles.label()),
          Expanded(child: Text(text, style: AppTextStyles.bodySm())),
        ],
      ),
    );
  }
}
