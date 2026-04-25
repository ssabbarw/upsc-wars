import 'package:flutter/material.dart';

import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';

import 'share_link_kind.dart';

/// Returns `SessionConfig.mode`: `'exam'` (Normal) or `'learning'`, or `null`
/// if the sheet is dismissed without starting.
Future<String?> showShareLinkTestModeSheet({
  required BuildContext context,
  required String subject,
  required String? topic,
  required int questionCount,
  required ShareLinkKind kind,
  bool dismissible = true,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ShareLinkTestModeSheetBody(
      subject: subject,
      topic: topic,
      questionCount: questionCount,
      kind: kind,
      dismissible: dismissible,
    ),
  );
}

class _ShareLinkTestModeSheetBody extends StatefulWidget {
  const _ShareLinkTestModeSheetBody({
    required this.subject,
    required this.topic,
    required this.questionCount,
    required this.kind,
    required this.dismissible,
  });

  final String subject;
  final String? topic;
  final int questionCount;
  final ShareLinkKind kind;
  final bool dismissible;

  @override
  State<_ShareLinkTestModeSheetBody> createState() =>
      _ShareLinkTestModeSheetBodyState();
}

class _ShareLinkTestModeSheetBodyState extends State<_ShareLinkTestModeSheetBody> {
  String _mode = 'learning';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    final kindLabel = switch (widget.kind) {
      ShareLinkKind.question => 'Shared question',
      ShareLinkKind.battle => 'Shared set',
      ShareLinkKind.test => 'Shared test',
    };
    final topicTrim = widget.topic?.trim();
    final topicLine =
        topicTrim != null && topicTrim.isNotEmpty ? topicTrim : null;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? scheme.surfaceContainerHigh : scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    kindLabel,
                    style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
                  ),
                ),
                if (widget.dismissible)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.subject,
              style: AppTextStyles.body().copyWith(color: scheme.onSurface),
            ),
            if (topicLine != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                topicLine,
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${widget.questionCount} question${widget.questionCount == 1 ? '' : 's'}',
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'How do you want to run it?',
              style: AppTextStyles.label().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'learning',
                  label: Text('Learning'),
                ),
                ButtonSegment<String>(
                  value: 'exam',
                  label: Text('Normal'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) {
                setState(() => _mode = s.first);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _mode == 'learning'
                    ? Text(
                        'Learning — After you pick an answer you log how sure you '
                        'were, then see the full explanation before the next '
                        'question. A timer applies to each question.',
                        style: AppTextStyles.bodyMd().copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      )
                    : Text(
                        'Normal — Exam-style attempt: Prelims-style +/− scoring '
                        'for the whole set, one timer for the entire test. You '
                        'review explanations after you finish.',
                        style: AppTextStyles.bodyMd().copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.pop(context, _mode),
              child: Text(
                _mode == 'exam'
                    ? 'Start in exam mode'
                    : 'Start in learning mode',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
