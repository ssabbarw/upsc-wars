import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/super_user_provider.dart';

/// Whether the question editor is compiled in (debug / dart-define).
bool get isQuestionEditorEnabled =>
    kDebugMode || FeatureFlags.questionEditor;

/// Question editor routes and edit affordances (compile flag or super user).
bool canAccessQuestionEditor({required bool isSuperUser}) =>
    isQuestionEditorEnabled || isSuperUser;

/// Opens the question editor for [uuid]. No-op when access is denied.
Future<void> openQuestionEditorForUuid(
  BuildContext context,
  String uuid, {
  required bool isSuperUser,
  Future<void> Function()? onReturned,
}) async {
  if (!canAccessQuestionEditor(isSuperUser: isSuperUser)) return;
  final id = uuid.trim();
  if (id.isEmpty) return;
  await context.push('/internal/question-editor/edit', extra: id);
  if (context.mounted) {
    await onReturned?.call();
  }
}

/// Compact edit affordance for question screens (super user / debug builds).
class QuestionEditorIconButton extends ConsumerWidget {
  const QuestionEditorIconButton({
    required this.questionUuid,
    this.onReturned,
    super.key,
  });

  final String questionUuid;
  final Future<void> Function()? onReturned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuperUser = ref.watch(isSuperUserProvider);
    if (!canAccessQuestionEditor(isSuperUser: isSuperUser)) {
      return const SizedBox.shrink();
    }
    return IconButton(
      tooltip: 'Edit question',
      icon: const Icon(Icons.edit_outlined, size: 20),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      onPressed: () => openQuestionEditorForUuid(
        context,
        questionUuid,
        isSuperUser: isSuperUser,
        onReturned: onReturned,
      ),
    );
  }
}
