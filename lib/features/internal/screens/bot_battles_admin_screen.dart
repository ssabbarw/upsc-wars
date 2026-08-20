import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';

import '../../../core/admin_dashboard/admin_dashboard_period.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/bot_battles_admin_service.dart';

/// Super-user funnel for human vs traffic-bot MCQ battles.
class BotBattlesAdminScreen extends HookWidget {
  const BotBattlesAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final period = useState(AdminDashboardPeriod.day);
    final reload = useState(0);
    final future = useMemoized(
      () => BotBattlesAdminService().load(period: period.value),
      [period.value, reload.value],
    );
    final snap = useFuture(future);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bot battles'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => reload.value++,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'People who started or finished a 1v1 with a Recents bot. '
            'Synthetic offline-bot games are not counted.',
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final item in [
                AdminDashboardPeriod.day,
                AdminDashboardPeriod.week,
                AdminDashboardPeriod.month,
              ])
                ChoiceChip(
                  label: Text(item.label),
                  selected: period.value == item,
                  onSelected: (_) => period.value = item,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (snap.connectionState != ConnectionState.done)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (snap.hasError)
            Text(
              'Could not load bot battle stats.',
              style: AppTextStyles.body().copyWith(color: scheme.error),
            )
          else if (snap.data == null)
            Text(
              'No bot battle stats yet.',
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            _LoadedBody(data: snap.data!),
        ],
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.data});

  final BotBattlesAdminSnapshot data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rate = data.uniqueJoins == 0
        ? '—'
        : '${(data.completionRate * 100).round()}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'People joined',
                value: '${data.uniqueJoins}',
                hint: '${data.joinSessions} sessions',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                label: 'People finished',
                value: '${data.uniqueCompletions}',
                hint: '${data.completionSessions} sessions · $rate',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Text(
            'Last 24h · ${data.peopleLast24h} joined · '
            '${data.completedPeopleLast24h} finished',
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Recent battles',
          style: AppTextStyles.label().copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (data.recent.isEmpty)
          Text(
            'No bot battles recorded yet. Counts start after the next deploy.',
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          for (final session in data.recent) _SessionTile(session: session),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.h1().copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final BotBattleSession session;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final when = session.joinedAtMs > 0
        ? DateFormat('d MMM, h:mm a').format(
            DateTime.fromMillisecondsSinceEpoch(session.joinedAtMs),
          )
        : session.dateId;
    final human = session.humanDisplayName.isNotEmpty
        ? session.humanDisplayName
        : session.humanEmail;
    final bot = session.botName.isNotEmpty ? session.botName : session.botEmail;
    final whoStarted = session.isOutgoing ? '$bot invited' : '$human invited';
    final status = session.isCompleted ? 'Finished' : 'Joined';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    human,
                    style: AppTextStyles.label().copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  status,
                  style: AppTextStyles.caption().copyWith(
                    color: session.isCompleted
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'vs $bot · ${session.subject.isEmpty ? 'Battle' : session.subject}',
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            Text(
              '$whoStarted · $when',
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (session.humanEmail.isNotEmpty)
              Text(
                session.humanEmail,
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
