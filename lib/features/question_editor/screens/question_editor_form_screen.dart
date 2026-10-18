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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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

    void patch(
      QuestionEditorDraft Function(QuestionEditorDraft current) update,
    ) {
      draft.value = update(draft.value!);
    }

    final isDirty = draft.value!.isDirtyComparedTo(orig);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${d.uuid.substring(0, 8)}…'),
        actions: [
          TextButton(
            onPressed: isDirty
                ? () => context.push(
                    '/internal/question-editor/preview',
                    extra: QuestionEditorPreviewArgs(
                      original: orig,
                      edited: draft.value!,
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
                    if (v != null) {
                      patch((current) => current.copyWith(correctOption: v));
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _StableMultilineField(
                  key: ValueKey('trap-${d.uuid}'),
                  label: 'Trap type',
                  value: d.trapType,
                  onChanged: (v) =>
                      patch((current) => current.copyWith(trapType: v)),
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
  final void Function(QuestionEditorDraft Function(QuestionEditorDraft) update)
  onPatch;

  @override
  Widget build(BuildContext context) {
    QuestionEditorDraft patchLang(
      QuestionEditorDraft current, {
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
        return current.copyWith(
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
      return current.copyWith(
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

    final stem = isHindi ? draft.stemHi : draft.stemEn;
    final oa = isHindi ? draft.optionAHi : draft.optionAEn;
    final ob = isHindi ? draft.optionBHi : draft.optionBEn;
    final oc = isHindi ? draft.optionCHi : draft.optionCEn;
    final od = isHindi ? draft.optionDHi : draft.optionDEn;
    final body = isHindi
        ? draft.finalExplanationBodyHi
        : draft.finalExplanationBodyEn;
    final valueAdd = isHindi ? draft.valueAdditionHi : draft.valueAdditionEn;
    final elim = isHindi ? draft.eliminationLogicHi : draft.eliminationLogicEn;
    final distractor = isHindi
        ? draft.strongDistractorHi
        : draft.strongDistractorEn;
    final trap = isHindi
        ? draft.upscTrapExplanationHi
        : draft.upscTrapExplanationEn;
    final stmt = isHindi
        ? draft.statementAnalysisHi
        : draft.statementAnalysisEn;
    final lang = isHindi ? 'HI' : 'EN';

    return Column(
      children: [
        _field(
          'Statement ($lang)',
          stem,
          (v) => onPatch((c) => patchLang(c, stem: v)),
          lang: lang,
        ),
        _field(
          'Option A',
          oa,
          (v) => onPatch((c) => patchLang(c, a: v)),
          lang: lang,
        ),
        _field(
          'Option B',
          ob,
          (v) => onPatch((c) => patchLang(c, b: v)),
          lang: lang,
        ),
        _field(
          'Option C',
          oc,
          (v) => onPatch((c) => patchLang(c, c: v)),
          lang: lang,
        ),
        _field(
          'Option D',
          od,
          (v) => onPatch((c) => patchLang(c, optD: v)),
          lang: lang,
        ),
        _field(
          'Final explanation',
          body,
          (v) => onPatch((c) => patchLang(c, body: v)),
          minLines: 6,
          lang: lang,
        ),
        _field(
          'Value addition',
          valueAdd,
          (v) => onPatch((c) => patchLang(c, valueAdd: v)),
          minLines: 3,
          lang: lang,
        ),
        _field(
          'Elimination (one step per line)',
          elim.join('\n'),
          (v) => onPatch((current) => patchLang(current, elim: v.split('\n'))),
          minLines: 6,
          lang: lang,
        ),
        _field(
          'Strong distractor',
          distractor,
          (v) => onPatch((c) => patchLang(c, distractor: v)),
          minLines: 2,
          lang: lang,
        ),
        _field(
          'UPSC trap explanation',
          trap,
          (v) => onPatch((c) => patchLang(c, trap: v)),
          minLines: 3,
          lang: lang,
        ),
        _StatementAnalysisEditor(
          items: stmt,
          onChanged: (items) => onPatch((c) => patchLang(c, stmt: items)),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    int minLines = 2,
    required String lang,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: _StableMultilineField(
        key: ValueKey('field-$lang-$label'),
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

class _StatementAnalysisEditor extends StatelessWidget {
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
            key: ValueKey('stmt-${e.key}'),
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

class _StatementRow extends StatefulWidget {
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
  State<_StatementRow> createState() => _StatementRowState();
}

class _StatementRowState extends State<_StatementRow> {
  late final TextEditingController _labelController;
  late final TextEditingController _reasonController;
  late bool _isCorrect;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.item.label);
    _reasonController = TextEditingController(text: widget.item.reason);
    _isCorrect = widget.item.isCorrect;
  }

  @override
  void didUpdateWidget(covariant _StatementRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.label != widget.item.label &&
        _labelController.text != widget.item.label) {
      _labelController.text = widget.item.label;
    }
    if (oldWidget.item.reason != widget.item.reason &&
        _reasonController.text != widget.item.reason) {
      _reasonController.text = widget.item.reason;
    }
    if (oldWidget.item.isCorrect != widget.item.isCorrect) {
      _isCorrect = widget.item.isCorrect;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onUpdate(
      StatementAnalysisItem(
        label: _labelController.text,
        isCorrect: _isCorrect,
        reason: _reasonController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Statement label',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              minLines: 2,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              onChanged: (_) => _emit(),
            ),
            SwitchListTile(
              title: const Text('Correct'),
              value: _isCorrect,
              onChanged: (v) {
                setState(() => _isCorrect = v);
                _emit();
              },
            ),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              onChanged: (_) => _emit(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onRemove,
                child: const Text('Remove'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
