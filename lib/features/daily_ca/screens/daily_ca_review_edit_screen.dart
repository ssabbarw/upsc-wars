import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/question_source_constants.dart';
import '../../../core/parsers/question_display_text_composer.dart';
import '../../../core/parsers/question_display_text_parser.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/ca_revision_tags.dart';

class DailyCaReviewEditScreen extends HookWidget {
  const DailyCaReviewEditScreen({required this.raw, super.key});

  final Map<String, dynamic> raw;

  @override
  Widget build(BuildContext context) {
    final meta = useState<Map<String, dynamic>>(
      raw['meta'] is Map
          ? Map<String, dynamic>.from(raw['meta'] as Map)
          : <String, dynamic>{},
    );
    final shared = useState<Map<String, dynamic>>(
      raw['shared'] is Map
          ? Map<String, dynamic>.from(raw['shared'] as Map)
          : <String, dynamic>{},
    );
    final en = useState<Map<String, dynamic>>(
      raw['en'] is Map
          ? Map<String, dynamic>.from(raw['en'] as Map)
          : <String, dynamic>{},
    );
    final parsed = QuestionDisplayTextParser.parse(
      (en.value['display_text'] ?? '').toString(),
    );
    final stem = useTextEditingController(text: parsed.stem);
    final a = useTextEditingController(text: parsed.optionA);
    final b = useTextEditingController(text: parsed.optionB);
    final c = useTextEditingController(text: parsed.optionC);
    final d = useTextEditingController(text: parsed.optionD);
    final explanation = useTextEditingController(
      text: (en.value['final_explanation'] ?? '').toString(),
    );
    final topic = useTextEditingController(
      text: (meta.value['topic'] ?? '').toString(),
    );
    final tags = useState<List<String>>(
      CaRevisionTags.sanitizeTags(meta.value['ca_tags']),
    );
    final initialGs = QuestionSourceConstants.normalizeGsSubject(
      (meta.value['gs_subject'] ?? 'Polity').toString(),
    );
    final gs = useState<String>(
      CaRevisionTags.gsSubjectSet.contains(initialGs) ? initialGs : 'Polity',
    );
    final correct = useState(
      (shared.value['correct_option'] ?? 'a').toString().toLowerCase(),
    );

    Map<String, dynamic>? table = en.value['table_data'] is Map
        ? Map<String, dynamic>.from(en.value['table_data'] as Map)
        : null;

    Future<void> editField(
      String label,
      String value,
      ValueChanged<String> onSave,
    ) async {
      final controller = TextEditingController(text: value);
      final next = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.lg,
              bottom: MediaQuery.viewInsetsOf(ctx).bottom + AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(label, style: AppTextStyles.label()),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: controller,
                  maxLines: 6,
                  autofocus: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, controller.text),
                  child: const Text('Save field'),
                ),
              ],
            ),
          );
        },
      );
      controller.dispose();
      if (next != null) onSave(next);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit question'),
        actions: [
          TextButton(
            onPressed: () {
              final nextEn = Map<String, dynamic>.from(en.value);
              nextEn['display_text'] = QuestionDisplayTextComposer.compose(
                stem: stem.text,
                optionA: a.text,
                optionB: b.text,
                optionC: c.text,
                optionD: d.text,
              );
              nextEn['final_explanation'] = explanation.text;
              if (table != null) nextEn['table_data'] = table;
              final nextMeta = Map<String, dynamic>.from(meta.value);
              nextMeta['gs_subject'] = gs.value;
              nextMeta['topic'] = topic.text.trim();
              nextMeta['ca_tags'] = tags.value;
              nextMeta['sub_topic'] =
                  CaRevisionTags.primaryTag(tags.value) ?? 'Current Affairs';
              nextMeta['concepts_used'] = tags.value;
              final nextShared = Map<String, dynamic>.from(shared.value);
              nextShared['correct_option'] = correct.value;
              context.pop({
                ...raw,
                'meta': nextMeta,
                'shared': nextShared,
                'en': nextEn,
              });
            },
            child: const Text('Done'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          DropdownButtonFormField<String>(
            initialValue: CaRevisionTags.gsSubjects.contains(gs.value)
                ? gs.value
                : CaRevisionTags.gsSubjects.first,
            decoration: const InputDecoration(
              labelText: 'GS subject',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final s in CaRevisionTags.gsSubjects)
                DropdownMenuItem(value: s, child: Text(s)),
            ],
            onChanged: (v) {
              if (v != null) gs.value = v;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: topic,
            decoration: const InputDecoration(
              labelText: 'Topic / hook',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('CA tags (1–3)', style: AppTextStyles.caption()),
          Wrap(
            spacing: 6,
            children: [
              for (final tag in CaRevisionTags.caTags)
                FilterChip(
                  label: Text(tag, style: AppTextStyles.caption()),
                  selected: tags.value.contains(tag),
                  onSelected: (on) {
                    final next = [...tags.value];
                    if (on) {
                      if (next.length >= CaRevisionTags.maxTags) return;
                      next.add(tag);
                    } else {
                      next.remove(tag);
                    }
                    tags.value = next;
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: ['a', 'b', 'c', 'd'].contains(correct.value)
                ? correct.value
                : 'a',
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
              if (v != null) correct.value = v;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: stem,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Stem',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: a,
            decoration: const InputDecoration(
              labelText: 'Option A',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: b,
            decoration: const InputDecoration(
              labelText: 'Option B',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: c,
            decoration: const InputDecoration(
              labelText: 'Option C',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: d,
            decoration: const InputDecoration(
              labelText: 'Option D',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: explanation,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Explanation',
              border: OutlineInputBorder(),
            ),
          ),
          if (table != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Table — tap a cell to edit', style: AppTextStyles.label()),
            const SizedBox(height: AppSpacing.sm),
            _TableEditor(
              table: table,
              onEdit: (label, value, save) => editField(label, value, save),
              onChanged: (next) {
                table = next;
                en.value = {...en.value, 'table_data': next};
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _TableEditor extends StatelessWidget {
  const _TableEditor({
    required this.table,
    required this.onEdit,
    required this.onChanged,
  });

  final Map<String, dynamic> table;
  final Future<void> Function(
    String label,
    String value,
    ValueChanged<String> onSave,
  )
  onEdit;
  final ValueChanged<Map<String, dynamic>> onChanged;

  List<String> get columns {
    final raw = table['columns'];
    if (raw is List && raw.length >= 2) {
      return raw.map((e) => e.toString()).toList();
    }
    return const ['List I', 'List II'];
  }

  List<Map<String, dynamic>> get rows {
    final raw = table['rows'];
    if (raw is! List) return const [];
    return [
      for (final row in raw)
        if (row is Map) Map<String, dynamic>.from(row),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cols = columns;
    final dataRows = rows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          dense: true,
          title: Text(
            (table['header_text'] ?? 'Header').toString(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.edit_outlined, size: 18),
          onTap: () => onEdit(
            'Header',
            (table['header_text'] ?? '').toString(),
            (v) => onChanged({...table, 'header_text': v}),
          ),
        ),
        Table(
          border: TableBorder.all(color: Theme.of(context).dividerColor),
          children: [
            TableRow(
              children: [
                for (final col in cols)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(col, style: AppTextStyles.caption()),
                  ),
              ],
            ),
            for (var r = 0; r < dataRows.length; r++)
              TableRow(
                children: [
                  for (var c = 0; c < cols.length; c++)
                    InkWell(
                      onTap: () {
                        final key = cols[c];
                        final current =
                            (dataRows[r][key] ?? dataRows[r]['col_$c'] ?? '')
                                .toString();
                        onEdit('Row ${r + 1} · $key', current, (v) {
                          final nextRows = [
                            for (var i = 0; i < dataRows.length; i++)
                              Map<String, dynamic>.from(dataRows[i]),
                          ];
                          nextRows[r][key] = v;
                          nextRows[r]['col_$c'] = v;
                          if (c == 0) nextRows[r]['list_i'] = v;
                          if (c == 1) nextRows[r]['list_ii'] = v;
                          onChanged({...table, 'rows': nextRows});
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          (dataRows[r][cols[c]] ?? dataRows[r]['col_$c'] ?? '')
                              .toString(),
                          style: AppTextStyles.caption(),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
        ListTile(
          dense: true,
          title: Text(
            (table['footer_text'] ?? 'Footer / options').toString(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.edit_outlined, size: 18),
          onTap: () => onEdit(
            'Footer / options',
            (table['footer_text'] ?? '').toString(),
            (v) => onChanged({...table, 'footer_text': v}),
          ),
        ),
      ],
    );
  }
}
