import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';
import '../domain/subject_mcq_pattern.dart';

/// Title + body for an MCQ stem shape (How many, Match, Identify the pair, …).
void showMcqPatternInfo(BuildContext context, SubjectMcqPatternStat pattern) {
  final l10n = context.l10n;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(pattern.labelFor(l10n)),
      content: Text(pattern.explainFor(l10n), style: AppTextStyles.bodyMd()),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.commonGotIt),
        ),
      ],
    ),
  );
}

/// Compact i control that opens [showMcqPatternInfo].
class McqPatternInfoButton extends StatelessWidget {
  const McqPatternInfoButton({super.key, required this.pattern});

  final SubjectMcqPatternStat pattern;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: pattern.labelFor(context.l10n),
      onPressed: () => showMcqPatternInfo(context, pattern),
      icon: Icon(
        Icons.info_outline_rounded,
        size: 18,
        color: scheme.onSurfaceVariant,
      ),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
    );
  }
}
