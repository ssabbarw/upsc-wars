import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/daily_war_cloud_service.dart';
import '../domain/daily_war_copy.dart';
import '../domain/daily_war_schedule.dart';
import '../providers/daily_war_providers.dart';
import 'daily_war_admin_preview_screen.dart';

/// Super-user ops for tonight's Daily War paper (generate / review / publish).
class DailyWarAdminScreen extends HookConsumerWidget {
  const DailyWarAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final busy = useState(false);
    final preview = useState<DailyWarAdminPreview?>(null);
    final message = useState<String?>(null);
    final todayId = DailyWarSchedule.formatIsoDate(DailyWarSchedule.nowIst());

    Future<void> refreshHomeWar() async {
      await ref.read(dailyWarTodayDocProvider.notifier).refresh();
    }

    Future<void> run(Future<void> Function() action) async {
      if (busy.value) return;
      busy.value = true;
      message.value = null;
      try {
        await action();
      } finally {
        busy.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text(DailyWarCopy.programName)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Paper is private until 20:59 IST. Preview uses admin callable '
            '(not the public doc). Today: $todayId',
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton(
                onPressed: busy.value
                    ? null
                    : () => unawaited(
                        run(() async {
                          const cloud = DailyWarCloudService();
                          final ok = await cloud.adminGenerate(
                            dateId: todayId,
                            force: false,
                          );
                          preview.value = await cloud.adminPreview(
                            dateId: todayId,
                          );
                          await refreshHomeWar();
                          final topics = preview.value?.topics.length ?? 0;
                          message.value = ok
                              ? 'Generate ok · $todayId · $topics topics'
                              : 'Generate failed';
                        }),
                      ),
                child: const Text('Generate today'),
              ),
              OutlinedButton(
                onPressed: busy.value
                    ? null
                    : () => unawaited(
                        run(() async {
                          const cloud = DailyWarCloudService();
                          final ok = await cloud.adminGenerate(
                            dateId: todayId,
                            force: true,
                          );
                          preview.value = await cloud.adminPreview(
                            dateId: todayId,
                          );
                          await refreshHomeWar();
                          final topics = preview.value?.topics.length ?? 0;
                          message.value = ok
                              ? 'Force regenerated · $topics topics'
                              : 'Regenerate failed';
                        }),
                      ),
                child: const Text('Force regenerate'),
              ),
              OutlinedButton(
                onPressed: busy.value
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                DailyWarAdminPreviewScreen(dateId: todayId),
                          ),
                        );
                      },
                child: const Text('Review questions'),
              ),
              OutlinedButton(
                onPressed: busy.value
                    ? null
                    : () => unawaited(
                        run(() async {
                          const cloud = DailyWarCloudService();
                          preview.value = await cloud.adminPreview(
                            dateId: todayId,
                          );
                          message.value = preview.value == null
                              ? 'Preview failed — generate first?'
                              : 'Meta loaded · use Review questions for full paper';
                        }),
                      ),
                child: const Text('Preview meta'),
              ),
              OutlinedButton(
                onPressed: busy.value
                    ? null
                    : () => unawaited(
                        run(() async {
                          const cloud = DailyWarCloudService();
                          final ok = await cloud.adminPublish(dateId: todayId);
                          message.value = ok
                              ? 'Published to public path'
                              : 'Publish failed';
                          preview.value = await cloud.adminPreview(
                            dateId: todayId,
                          );
                        }),
                      ),
                child: const Text('Publish now'),
              ),
              OutlinedButton(
                onPressed: busy.value
                    ? null
                    : () => unawaited(
                        run(() async {
                          const cloud = DailyWarCloudService();
                          final ok = await cloud.adminNotify(
                            dateId: todayId,
                            phase: 'morning',
                          );
                          message.value = ok
                              ? 'Sent morning topics push'
                              : 'Morning push failed (generate first?)';
                        }),
                      ),
                child: const Text('Push: morning'),
              ),
              OutlinedButton(
                onPressed: busy.value
                    ? null
                    : () => unawaited(
                        run(() async {
                          const cloud = DailyWarCloudService();
                          final ok = await cloud.adminNotify(
                            dateId: todayId,
                            phase: 'lobby',
                          );
                          message.value = ok
                              ? 'Sent lobby push'
                              : 'Lobby push failed';
                        }),
                      ),
                child: const Text('Push: lobby'),
              ),
              OutlinedButton(
                onPressed: busy.value
                    ? null
                    : () => unawaited(
                        run(() async {
                          const cloud = DailyWarCloudService();
                          final ok = await cloud.adminNotify(
                            dateId: todayId,
                            phase: 'results',
                          );
                          message.value = ok
                              ? 'Sent results push (also re-ranks)'
                              : 'Results push failed';
                        }),
                      ),
                child: const Text('Push: results'),
              ),
            ],
          ),
          if (busy.value) ...[
            const SizedBox(height: AppSpacing.sm),
            const LinearProgressIndicator(),
          ],
          if (message.value != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(message.value!, style: AppTextStyles.bodySm()),
          ],
          if (preview.value case final p?) ...[
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p.kind} · ${p.status} · '
                      '${p.isPubliclyPublished ? "PUBLIC" : "PRIVATE only"}',
                      style: AppTextStyles.label(),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${p.questionCount} Q · private UUIDs: ${p.privateUuids.length} · '
                      'public UUIDs: ${p.publicUuids.length}',
                      style: AppTextStyles.bodySm(),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    for (final t in p.topics)
                      Text(
                        '${t['subject']} — ${t['topic']}',
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    if (p.privateUuids.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'First UUID: ${p.privateUuids.first}',
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
