import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/fomo_pulse_models.dart';
import '../providers/fomo_pulse_providers.dart';

/// Lists today's Daily CA harvest. Tapping opens a preview — no LLM yet.
class FomoPulseComposerScreen extends HookConsumerWidget {
  const FomoPulseComposerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = useState(0);
    final urlCtrl = useTextEditingController();
    final harvestLoading = useState(true);
    final harvestDate = useState<String?>(null);
    final candidates = useState<List<FomoPulseHarvestCandidate>>([]);
    final scheme = Theme.of(context).colorScheme;

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
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(title: const Text('Pulse composer')),
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
            segments: const [
              ButtonSegment(value: 0, label: Text("Today's news")),
              ButtonSegment(value: 1, label: Text('URL')),
            ],
            selected: {tab.value},
            onSelectionChanged: (s) => tab.value = s.first,
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
          ] else ...[
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
          ],
        ],
      ),
    );
  }
}
