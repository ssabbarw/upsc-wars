import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/question_editor_providers.dart';

class QuestionEditorSearchScreen extends HookConsumerWidget {
  const QuestionEditorSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final uuidController = useTextEditingController();
    final textController = useTextEditingController();
    final uuidHits = useState<List<QuestionSearchHitVm>>(const []);
    final textMeta = useState<QuestionTextSearchVm?>(null);
    final busy = useState(false);
    final error = useState<String?>(null);

    Future<void> runUuidSearch(String raw) async {
      final q = raw.trim();
      if (q.length < 4) {
        uuidHits.value = const [];
        return;
      }
      busy.value = true;
      error.value = null;
      try {
        final repo = await ref.read(questionEditorRepositoryProvider.future);
        final hits = await repo.searchByUuidPrefix(q);
        uuidHits.value = hits
            .map(
              (h) => QuestionSearchHitVm(
                uuid: h.uuid,
                preview: h.preview,
                subject: h.subject,
              ),
            )
            .toList();
      } catch (e) {
        error.value = e.toString();
      } finally {
        busy.value = false;
      }
    }

    Future<void> runTextSearch(String raw) async {
      final q = raw.trim();
      if (q.length < 8) {
        textMeta.value = null;
        return;
      }
      busy.value = true;
      error.value = null;
      try {
        final repo = await ref.read(questionEditorRepositoryProvider.future);
        final result = await repo.searchByTextSnippet(q);
        if (result.first == null) {
          textMeta.value = const QuestionTextSearchVm(totalMatches: 0);
          return;
        }
        textMeta.value = QuestionTextSearchVm(
          uuid: result.first!.uuid,
          preview: (result.first!.enDisplayText ?? '').trim(),
          totalMatches: result.totalMatches,
        );
      } catch (e) {
        error.value = e.toString();
      } finally {
        busy.value = false;
      }
    }

    useEffect(() {
      Timer? timer;
      void onUuidChanged() {
        timer?.cancel();
        timer = Timer(const Duration(milliseconds: 300), () {
          unawaited(runUuidSearch(uuidController.text));
        });
      }

      uuidController.addListener(onUuidChanged);
      return () {
        timer?.cancel();
        uuidController.removeListener(onUuidChanged);
      };
    }, [uuidController]);

    void openEditor(String uuid) {
      context.push('/internal/question-editor/edit', extra: uuid);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Question editor')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Find a question by UUID prefix or by pasting statement text.',
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: uuidController,
            decoration: const InputDecoration(
              labelText: 'UUID',
              hintText: 'Paste or type uuid…',
              border: OutlineInputBorder(),
            ),
            autocorrect: false,
          ),
          if (uuidHits.value.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ...uuidHits.value.map(
              (h) => ListTile(
                title: Text(h.uuid, style: AppTextStyles.label()),
                subtitle: Text('${h.subject} · ${h.preview}'),
                onTap: () => openEditor(h.uuid),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'Statement text',
              hintText: 'Paste question stem (min 8 chars)…',
              border: OutlineInputBorder(),
            ),
            minLines: 3,
            maxLines: 6,
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: busy.value
                ? null
                : () => unawaited(runTextSearch(textController.text)),
            child: const Text('Find first match'),
          ),
          if (textMeta.value != null) ...[
            const SizedBox(height: AppSpacing.md),
            Builder(
              builder: (context) {
                final meta = textMeta.value!;
                if (meta.totalMatches == 0) {
                  return Text(
                    'No matches.',
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  );
                }
                return Card(
                  child: ListTile(
                    title: Text(meta.uuid ?? '', style: AppTextStyles.label()),
                    subtitle: Text(
                      '${meta.totalMatches} match(es). Showing first.\n${meta.preview}',
                    ),
                    trailing: meta.uuid == null
                        ? null
                        : const Icon(Icons.chevron_right),
                    onTap: meta.uuid == null
                        ? null
                        : () => openEditor(meta.uuid!),
                  ),
                );
              },
            ),
          ],
          if (busy.value)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (error.value != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                error.value!,
                style: AppTextStyles.bodySm().copyWith(color: scheme.error),
              ),
            ),
        ],
      ),
    );
  }
}

class QuestionSearchHitVm {
  const QuestionSearchHitVm({
    required this.uuid,
    required this.preview,
    required this.subject,
  });

  final String uuid;
  final String preview;
  final String subject;
}

class QuestionTextSearchVm {
  const QuestionTextSearchVm({
    this.uuid,
    this.preview = '',
    required this.totalMatches,
  });

  final String? uuid;
  final String preview;
  final int totalMatches;
}
