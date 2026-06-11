import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/test_question.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/question_editor_repository.dart';
import '../domain/question_editor_draft.dart';
import '../providers/question_editor_providers.dart';
import 'question_editor_preview_screen.dart';

class QuestionEditorFormScreen extends HookConsumerWidget {
  const QuestionEditorFormScreen({required this.uuid, super.key});

  final String uuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundle = useState<QuestionEditorLoadBundle?>(null);
    final original = useRef<QuestionEditorDraft?>(null);
    final draft = useState<QuestionEditorDraft?>(null);
    final loading = useState(true);
    final error = useState<String?>(null);
    final langTab = useState(0);

    useEffect(() {
      Future<void> load() async {
        loading.value = true;
        error.value = null;
        try {
          final repo = await ref.read(questionEditorRepositoryProvider.future);
          final loaded = await repo.loadByUuid(uuid);
          if (loaded == null) {
            error.value = 'Question not found: $uuid';
            return;
          }
          bundle.value = loaded;
          original.value = loaded.draft;
          draft.value = loaded.draft;
        } catch (e) {
          error.value = e.toString();
        } finally {
          loading.value = false;
        }
      }

      unawaited(load());
      return null;
    }, [uuid]);

    if (loading.value) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error.value != null || draft.value == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(error.value ?? 'Unknown error')),
      );
    }

    final d = draft.value!;
    final orig = original.value!;
    final hasTable = d.hasTable;

    void patch(QuestionEditorDraft next) => draft.value = next;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${d.uuid.substring(0, 8)}…'),
        actions: [
          TextButton(
            onPressed: d.isDirtyComparedTo(orig)
                ? () => context.push(
                    '/internal/question-editor/preview',
                    extra: QuestionEditorPreviewArgs(
                      original: orig,
                      edited: d,
                    ),
                  )
                : null,
            child: const Text('Preview'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (hasTable)
            const MaterialBanner(
              content: Text(
                'Table layout is not editable here. You can still fix options, answer key, and explanations.',
              ),
              actions: <Widget>[],
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('English'),
                  selected: langTab.value == 0,
                  onSelected: (_) => langTab.value = 0,
                ),
                const SizedBox(width: AppSpacing.sm),
                ChoiceChip(
                  label: const Text('Hindi'),
                  selected: langTab.value == 1,
                  onSelected: (_) => langTab.value = 1,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  '${d.subject} · ${d.topic} · ${d.subTopic}',
                  style: AppTextStyles.caption(),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  key: ValueKey(d.correctOption),
                  initialValue: d.correctOption.toLowerCase(),
                  decoration: const InputDecoration(
                    labelText: 'Correct option',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'a', child: Text('A')),
                    DropdownMenuItem(value: 'b', child: Text('B')),
                    DropdownMenuItem(value: 'c', child: Text('C')),
                    DropdownMenuItem(value: 'd', child: Text('D')),
                  ],
                  onChanged: (v) {
                    if (v != null) patch(d.copyWith(correctOption: v));
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _StableMultilineField(
                  key: ValueKey('trap-${d.uuid}'),
                  label: 'Trap type',
                  value: d.trapType,
                  onChanged: (v) => patch(d.copyWith(trapType: v)),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (langTab.value == 0)
                  _LangFields(
                    key: const ValueKey('en'),
                    draft: d,
                    isHindi: false,
                    onPatch: patch,
                  )
                else
                  _LangFields(
                    key: const ValueKey('hi'),
                    draft: d,
                    isHindi: true,
                    onPatch: patch,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LangFields extends StatelessWidget {
  const _LangFields({
    required super.key,
    required this.draft,
    required this.isHindi,
    required this.onPatch,
  });

  final QuestionEditorDraft draft;
  final bool isHindi;
  final void Function(QuestionEditorDraft) onPatch;

  @override
  Widget build(BuildContext context) {
    final d = draft;
    QuestionEditorDraft patchLang({
      String? stem,
      String? a,
      String? b,
      String? c,
      String? optD,
      String? body,
      String? valueAdd,
      List<String>? elim,
      String? distractor,
      String? trap,
      List<StatementAnalysisItem>? stmt,
    }) {
      if (isHindi) {
        return d.copyWith(
          stemHi: stem,
          optionAHi: a,
          optionBHi: b,
          optionCHi: c,
          optionDHi: optD,
          finalExplanationBodyHi: body,
          valueAdditionHi: valueAdd,
          eliminationLogicHi: elim,
          strongDistractorHi: distractor,
          upscTrapExplanationHi: trap,
          statementAnalysisHi: stmt,
        );
      }
      return d.copyWith(
        stemEn: stem,
        optionAEn: a,
        optionBEn: b,
        optionCEn: c,
        optionDEn: optD,
        finalExplanationBodyEn: body,
        valueAdditionEn: valueAdd,
        eliminationLogicEn: elim,
        strongDistractorEn: distractor,
        upscTrapExplanationEn: trap,
        statementAnalysisEn: stmt,
      );
    }

    final stem = isHindi ? d.stemHi : d.stemEn;
    final oa = isHindi ? d.optionAHi : d.optionAEn;
    final ob = isHindi ? d.optionBHi : d.optionBEn;
    final oc = isHindi ? d.optionCHi : d.optionCEn;
    final od = isHindi ? d.optionDHi : d.optionDEn;
    final body = isHindi ? d.finalExplanationBodyHi : d.finalExplanationBodyEn;
    final valueAdd = isHindi ? d.valueAdditionHi : d.valueAdditionEn;
    final elim = isHindi ? d.eliminationLogicHi : d.eliminationLogicEn;
    final distractor = isHindi ? d.strongDistractorHi : d.strongDistractorEn;
    final trap = isHindi ? d.upscTrapExplanationHi : d.upscTrapExplanationEn;
    final stmt = isHindi ? d.statementAnalysisHi : d.statementAnalysisEn;
    final lang = isHindi ? 'HI' : 'EN';

    return Column(
      children: [
        _field('Statement ($lang)', stem, (v) => onPatch(patchLang(stem: v))),
        _field('Option A', oa, (v) => onPatch(patchLang(a: v))),
        _field('Option B', ob, (v) => onPatch(patchLang(b: v))),
        _field('Option C', oc, (v) => onPatch(patchLang(c: v))),
        _field('Option D', od, (v) => onPatch(patchLang(optD: v))),
        _field(
          'Final explanation',
          body,
          (v) => onPatch(patchLang(body: v)),
          minLines: 6,
        ),
        _field(
          'Value addition',
          valueAdd,
          (v) => onPatch(patchLang(valueAdd: v)),
          minLines: 3,
        ),
        _field(
          'Elimination (one step per line)',
          elim.join('\n'),
          (v) => onPatch(
            patchLang(
              elim: [
                for (final line in v.split('\n'))
                  if (line.trim().isNotEmpty) line.trim(),
              ],
            ),
          ),
          minLines: 4,
        ),
        _field(
          'Strong distractor',
          distractor,
          (v) => onPatch(patchLang(distractor: v)),
        ),
        _field(
          'UPSC trap explanation',
          trap,
          (v) => onPatch(patchLang(trap: v)),
          minLines: 3,
        ),
        _StatementAnalysisEditor(
          items: stmt,
          onChanged: (items) => onPatch(patchLang(stmt: items)),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    int minLines = 2,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: _StableMultilineField(
        key: ValueKey('field-$label'),
        label: label,
        value: value,
        minLines: minLines,
        onChanged: onChanged,
      ),
    );
  }
}

class _StableMultilineField extends StatefulWidget {
  const _StableMultilineField({
    required super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.minLines = 2,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final int minLines;

  @override
  State<_StableMultilineField> createState() => _StableMultilineFieldState();
}

class _StableMultilineFieldState extends State<_StableMultilineField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _StableMultilineField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
      minLines: widget.minLines,
      maxLines: null,
      onChanged: widget.onChanged,
    );
  }
}

class _StatementAnalysisEditor extends HookWidget {
  const _StatementAnalysisEditor({
    required this.items,
    required this.onChanged,
  });

  final List<StatementAnalysisItem> items;
  final ValueChanged<List<StatementAnalysisItem>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Statement analysis', style: AppTextStyles.label()),
        const SizedBox(height: AppSpacing.sm),
        ...items.asMap().entries.map((e) {
          return _StatementRow(
            key: ValueKey('stmt-${e.key}-${e.value.label}'),
            item: e.value,
            onUpdate: (item) {
              final next = [...items];
              next[e.key] = item;
              onChanged(next);
            },
            onRemove: () {
              final next = [...items]..removeAt(e.key);
              onChanged(next);
            },
          );
        }),
        OutlinedButton.icon(
          onPressed: () {
            onChanged([
              ...items,
              const StatementAnalysisItem(
                label: '',
                isCorrect: true,
                reason: '',
              ),
            ]);
          },
          icon: const Icon(Icons.add),
          label: const Text('Add statement'),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _StatementRow extends HookWidget {
  const _StatementRow({
    required super.key,
    required this.item,
    required this.onUpdate,
    required this.onRemove,
  });

  final StatementAnalysisItem item;
  final ValueChanged<StatementAnalysisItem> onUpdate;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final label = useTextEditingController(text: item.label);
    final reason = useTextEditingController(text: item.reason);
    final correct = useState(item.isCorrect);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            TextField(
              controller: label,
              decoration: const InputDecoration(
                labelText: 'Statement label',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => onUpdate(
                StatementAnalysisItem(
                  label: v,
                  isCorrect: correct.value,
                  reason: reason.text,
                ),
              ),
            ),
            SwitchListTile(
              title: const Text('Correct'),
              value: correct.value,
              onChanged: (v) {
                correct.value = v;
                onUpdate(
                  StatementAnalysisItem(
                    label: label.text,
                    isCorrect: v,
                    reason: reason.text,
                  ),
                );
              },
            ),
            TextField(
              controller: reason,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => onUpdate(
                StatementAnalysisItem(
                  label: label.text,
                  isCorrect: correct.value,
                  reason: v,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRemove,
                child: const Text('Remove'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
