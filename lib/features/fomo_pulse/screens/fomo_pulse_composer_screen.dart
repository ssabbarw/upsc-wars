import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/admin_pulse_draft_store.dart';
import '../data/fomo_pulse_incoming_share.dart';
import '../domain/fomo_pulse_models.dart';
import '../providers/fomo_pulse_providers.dart';

String _statusLabel(AdminPulseDraftStatus s) => switch (s) {
  AdminPulseDraftStatus.draft => 'Draft',
  AdminPulseDraftStatus.sentSelf => 'Sent to me',
  AdminPulseDraftStatus.sentBroadcast => 'Broadcast',
};

Color _statusColor(AdminPulseDraftStatus s, ColorScheme cs) => switch (s) {
  AdminPulseDraftStatus.draft => cs.onSurfaceVariant,
  AdminPulseDraftStatus.sentSelf => cs.primary,
  AdminPulseDraftStatus.sentBroadcast => cs.tertiary,
};

List<Widget> _buildSavedDraftTiles(
  BuildContext context,
  List<AdminPulseDraft> drafts,
  AdminPulseDraftStore store, {
  required VoidCallback onDeleted,
}) {
  final cs = Theme.of(context).colorScheme;
  return [
    for (final saved in drafts)
      Dismissible(
        key: ValueKey(saved.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          color: cs.error,
          child: Icon(Icons.delete, color: cs.onError),
        ),
        confirmDismiss: (_) async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete saved draft?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          return ok == true;
        },
        onDismissed: (_) {
          store.delete(saved.id);
          onDeleted();
        },
        child: Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ListTile(
            title: Text(
              saved.draft.notificationTitle.isNotEmpty
                  ? saved.draft.notificationTitle
                  : Uri.tryParse(saved.draft.sourceUrl)?.host ??
                        saved.draft.sourceUrl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              [
                _statusLabel(saved.status),
                if (saved.draft.sourceUrl.isNotEmpty)
                  Uri.tryParse(saved.draft.sourceUrl)?.host ?? '',
              ].join(' · '),
              style: TextStyle(color: _statusColor(saved.status, cs)),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(
              '/internal/fomo-pulse-composer/article',
              extra: FomoPulseArticleArgs.url(
                url: saved.draft.sourceUrl,
                savedDraft: saved.draft,
              ),
            ),
          ),
        ),
      ),
  ];
}

/// Lists today's Daily CA harvest. Tapping opens a preview — no LLM yet.
class FomoPulseComposerScreen extends HookConsumerWidget {
  const FomoPulseComposerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = useState(0);
    final urlCtrl = useTextEditingController();
    useListenable(urlCtrl);
    final harvestLoading = useState(true);
    final harvestDate = useState<String?>(null);
    final candidates = useState<List<FomoPulseHarvestCandidate>>([]);
    final savedDrafts = useState<List<AdminPulseDraft>>([]);
    final savedLoading = useState(false);
    final scheme = Theme.of(context).colorScheme;
    final draftStore = useMemoized(AdminPulseDraftStore.new);

    void reloadSaved() {
      unawaited(() async {
        savedLoading.value = true;
        try {
          savedDrafts.value = await draftStore.loadAll();
        } finally {
          savedLoading.value = false;
        }
      }());
    }

    useEffect(() {
      unawaited(() async {
        harvestLoading.value = true;
        try {
          final cloud = ref.read(fomoPulseCloudServiceProvider);
          final result = await cloud.listHarvestCandidates();
          harvestDate.value = result.draftDate;
          candidates.value = result.candidates;
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not load harvest: $e')),
            );
          }
        } finally {
          harvestLoading.value = false;
        }
      }());
      reloadSaved();
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(title: const Text('CA Shot composer')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Today’s news comes from the Daily CA pipeline '
            '(yesterday/today’s harvest in daily_ca_drafts). '
            'Tap a story to preview it. The MCQ is generated only when you tap '
            'Make question.',
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SegmentedButton<int>(
            segments: [
              const ButtonSegment(value: 0, label: Text("Today's news")),
              const ButtonSegment(value: 1, label: Text('URL')),
              ButtonSegment(
                value: 2,
                label: Text(
                  savedDrafts.value.isEmpty
                      ? 'Saved'
                      : 'Saved (${savedDrafts.value.length})',
                ),
              ),
            ],
            selected: {tab.value},
            onSelectionChanged: (s) {
              tab.value = s.first;
              if (s.first == 2) reloadSaved();
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          if (tab.value == 0) ...[
            if (harvestLoading.value)
              const Center(child: CircularProgressIndicator())
            else if (candidates.value.isEmpty)
              Text(
                harvestDate.value == null
                    ? 'No CA draft for today or yesterday. Run Daily CA, or paste a URL.'
                    : 'Draft ${harvestDate.value} has no items. Paste a URL instead.',
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else ...[
              Text(
                'Harvest date: ${harvestDate.value}',
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...candidates.value.map((c) {
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    title: Text(
                      c.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      [
                        if (c.gsSubject.isNotEmpty) c.gsSubject,
                        '★${c.newsImportance}',
                        if (c.sourceUrl.isNotEmpty)
                          Uri.tryParse(c.sourceUrl)?.host ?? '',
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: AppTextStyles.caption(),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      final date = harvestDate.value;
                      if (date == null) return;
                      context.push(
                        '/internal/fomo-pulse-composer/article',
                        extra: FomoPulseArticleArgs.harvest(
                          draftDate: date,
                          candidate: c,
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ] else if (tab.value == 1) ...[
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Article URL',
                hintText: 'https://…',
                helperText:
                    'Or share a page from Chrome/Safari to UPSC Wars. Make question runs on the next screen.',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => unawaited(_pasteUrlInto(context, urlCtrl)),
                    icon: const Icon(Icons.content_paste_rounded),
                    label: const Text('Paste URL'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: urlCtrl.text.isEmpty ? null : urlCtrl.clear,
                    icon: const Icon(Icons.clear_rounded),
                    label: const Text('Clear'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () {
                final url = urlCtrl.text.trim();
                if (url.isEmpty || !url.startsWith('http')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Paste a valid http(s) URL.')),
                  );
                  return;
                }
                context.push(
                  '/internal/fomo-pulse-composer/article',
                  extra: FomoPulseArticleArgs.url(url: url),
                );
              },
              child: const Text('Open article'),
            ),
          ] else ...[
            if (savedLoading.value)
              const Center(child: CircularProgressIndicator())
            else if (savedDrafts.value.isEmpty)
              Text(
                'No saved drafts yet. Generate a question from a URL or harvest story to save it here.',
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else
              ..._buildSavedDraftTiles(
                context,
                savedDrafts.value,
                draftStore,
                onDeleted: reloadSaved,
              ),
          ],
        ],
      ),
    );
  }
}

Future<void> _pasteUrlInto(
  BuildContext context,
  TextEditingController urlCtrl,
) async {
  final data = await Clipboard.getData(Clipboard.kTextPlain);
  final url = extractHttpUrlFromSharedText(data?.text ?? '');
  if (!context.mounted) return;
  if (url == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No http(s) URL on the clipboard.')),
    );
    return;
  }
  urlCtrl.text = url;
  urlCtrl.selection = TextSelection.collapsed(offset: url.length);
}
