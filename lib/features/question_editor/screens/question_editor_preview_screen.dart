import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_toast.dart';
import '../data/question_correction_mapper.dart';
import '../domain/question_editor_draft.dart';
import '../providers/question_editor_providers.dart';

class QuestionEditorPreviewArgs {
  const QuestionEditorPreviewArgs({
    required this.original,
    required this.edited,
  });

  final QuestionEditorDraft original;
  final QuestionEditorDraft edited;
}

class QuestionEditorPreviewScreen extends HookConsumerWidget {
  const QuestionEditorPreviewScreen({required this.args, super.key});

  final QuestionEditorPreviewArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final publishing = useState(false);
    final diffs = QuestionCorrectionMapper.diffDrafts(
      args.original,
      args.edited,
    );
    final correctOptionChanged = diffs.any((d) => d.label == 'Correct option');

    Future<void> publish() async {
      publishing.value = true;
      try {
        final repo = await ref.read(questionEditorRepositoryProvider.future);
        final outcome = await repo.publishCorrection(args.edited);
        if (!context.mounted) return;
        if (outcome.success) {
          AppToast.showText(
            context,
            'Published correction (revision ${outcome.revision ?? '?'})',
          );
          context.pop();
          context.pop();
          return;
        }
        AppToast.showText(
          context,
          outcome.message ?? 'Publish failed',
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        );
      } catch (e) {
        if (context.mounted) {
          AppToast.showText(context, e.toString());
        }
      } finally {
        publishing.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Preview correction')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('UUID: ${args.edited.uuid}', style: AppTextStyles.label()),
          const SizedBox(height: AppSpacing.sm),
          if (diffs.isEmpty)
            Text(
              'No changes detected.',
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            Text(
              '${diffs.length} field(s) changed',
              style: AppTextStyles.bodySm(),
            ),
          if (correctOptionChanged) ...[
            const SizedBox(height: AppSpacing.md),
            MaterialBanner(
              backgroundColor: scheme.errorContainer,
              content: const Text(
                'Correct option changed. Past attempts may have been scored under the old key.',
              ),
              actions: [
                TextButton(onPressed: () {}, child: const Text('Understood')),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          ...diffs.map(
            (d) => Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.label, style: AppTextStyles.label()),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Before', style: AppTextStyles.caption()),
                    SelectableText(
                      d.before.isEmpty ? '—' : d.before,
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('After', style: AppTextStyles.caption()),
                    SelectableText(
                      d.after.isEmpty ? '—' : d.after,
                      style: AppTextStyles.bodySm(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: publishing.value ? null : () => context.pop(),
                  child: const Text('Back to edit'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: diffs.isEmpty || publishing.value
                      ? null
                      : () => unawaited(publish()),
                  child: publishing.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Publish to Firebase'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
