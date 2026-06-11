import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/feature_flags.dart';

/// Whether the in-app question editor is available on this build.
bool get isQuestionEditorEnabled =>
    kDebugMode || FeatureFlags.questionEditor;

/// Opens the question editor for [uuid]. No-op when editor is disabled.
Future<void> openQuestionEditorForUuid(
  BuildContext context,
  String uuid, {
  Future<void> Function()? onReturned,
}) async {
  if (!isQuestionEditorEnabled) return;
  final id = uuid.trim();
  if (id.isEmpty) return;
  await context.push('/internal/question-editor/edit', extra: id);
  if (context.mounted) {
    await onReturned?.call();
  }
}

/// Compact edit affordance for question screens (debug / `ENABLE_QUESTION_EDITOR`).
class QuestionEditorIconButton extends StatelessWidget {
  const QuestionEditorIconButton({
    required this.questionUuid,
    this.onReturned,
    super.key,
  });

  final String questionUuid;
  final Future<void> Function()? onReturned;

  @override
  Widget build(BuildContext context) {
    if (!isQuestionEditorEnabled) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'Edit question',
      icon: const Icon(Icons.edit_outlined, size: 20),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      onPressed: () => openQuestionEditorForUuid(
        context,
        questionUuid,
        onReturned: onReturned,
      ),
    );
  }
}
