import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/qotd_comment_rules.dart';

/// Bottom sheet: optional comment with hint; empty or ≥50 chars after normalize; no newlines.
/// Returns `true` if [onPost] completed and the sheet closed successfully.
Future<bool> showQotdPostCommentSheet(
  BuildContext context, {
  required Future<void> Function(String comment) onPost,
}) async {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + AppSpacing.lg,
        ),
        child: Form(
          key: formKey,
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              void bump() => setModal(() {});

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Post to QOTD', style: AppTextStyles.h3()),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Optional note for the community. You learned something new? '
                      'Spotted something ironic? A concept felt challenged? '
                      'Be specific — or leave this blank.',
                      style: AppTextStyles.caption().copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: controller,
                      maxLines: 4,
                      minLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'[\r\n]')),
                        LengthLimitingTextInputFormatter(
                          QotdCommentRules.maxLength,
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Comment (optional)',
                        hintText:
                            'Leave blank, or write at least 50 characters…',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => bump(),
                      validator: QotdCommentRules.validateField,
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (context, v, _) {
                        final n = QotdCommentRules.normalize(v.text).length;
                        final scheme = Theme.of(context).colorScheme;
                        final need = QotdCommentRules.minLengthWhenNonEmpty;
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (n > 0 && n < need)
                                Text(
                                  '${need - n} more characters to reach $need, '
                                  'or clear the field to post without a comment.',
                                  style: AppTextStyles.caption().copyWith(
                                    color: scheme.error,
                                  ),
                                ),
                              Text(
                                '$n / ${QotdCommentRules.maxLength}',
                                style: AppTextStyles.caption().copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final text = QotdCommentRules.normalize(controller.text);
                        try {
                          await onPost(text);
                          if (ctx.mounted) Navigator.of(ctx).pop(true);
                        } catch (e, st) {
                          debugPrint('QOTD post failed: $e');
                          debugPrintStack(stackTrace: st);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('$e')),
                            );
                          }
                        }
                      },
                      child: const Text('Post'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  ).whenComplete(controller.dispose);
  return result ?? false;
}
