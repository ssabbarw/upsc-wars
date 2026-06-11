import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/admin_dashboard/admin_dashboard_collection_config.dart';
import '../../../core/admin_dashboard/admin_dashboard_period.dart';
import '../../../core/admin_dashboard/admin_dashboard_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/admin_dashboard_providers.dart';

/// Super-user dashboard for product metrics stored in Firestore.
class AdminDashboardScreen extends HookConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final period = useState(AdminDashboardPeriod.day);
    final summaryAsync = ref.watch(
      adminDashboardPeriodSummaryProvider(period.value),
    );
    final notificationsAsync = ref.watch(adminDashboardNotificationsProvider);
    final collectionAsync = ref.watch(adminDashboardCollectionEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminDashboardPeriodSummaryProvider(period.value));
          ref.invalidate(adminDashboardNotificationsProvider);
          ref.invalidate(adminDashboardCollectionEnabledProvider);
          await Future<void>.delayed(const Duration(milliseconds: 400));
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            collectionAsync.when(
              data: (enabled) {
                if (enabled) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: MaterialBanner(
                    content: Text(
                      'Collection is OFF via Remote Config '
                      '($adminDashboardCollectionEnabledRemoteConfigKey). '
                      'Historical data still loads; new events are not written.',
                      style: AppTextStyles.bodySm(),
                    ),
                    leading: Icon(
                      Icons.cloud_off_outlined,
                      color: scheme.error,
                    ),
                    backgroundColor: scheme.errorContainer.withValues(alpha: 0.35),
                    actions: const [SizedBox.shrink()],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            Text(
              'Period',
              style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: AdminDashboardPeriod.values.map((p) {
                final selected = period.value == p;
                return ChoiceChip(
                  label: Text(p.label),
                  selected: selected,
                  onSelected: (_) => period.value = p,
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            summaryAsync.when(
              data: (summary) => _MetricsSection(summary: summary),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text(
                'Failed to load metrics: $e',
                style: AppTextStyles.bodySm().copyWith(color: scheme.error),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Push notifications',
              style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.sm),
            notificationsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Text(
                    'No notification stats yet.',
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  );
                }
                return _NotificationsTable(items: items);
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text(
                'Failed to load notifications: $e',
                style: AppTextStyles.bodySm().copyWith(color: scheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsSection extends StatelessWidget {
  const _MetricsSection({required this.summary});

  final AdminDashboardPeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = <(String, int)>[
      ('New downloads', summary.newDownloads),
      ('Onboarding completed', summary.onboardingCompletedUsers),
      ('First demo test completed', summary.firstDemoTestUsers),
      ('First test (unique)', summary.firstTestUsers),
      ('Test takers (unique)', summary.testTakers),
      ('First memory game (unique)', summary.firstMemoryGameUsers),
      ('Memory game plays (total)', summary.memoryGamePlays),
      ('Battle users (unique)', summary.battleUsers),
      ('Chat users (unique)', summary.chatUsers),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      value.toString(),
                      style: AppTextStyles.h3().copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsTable extends StatelessWidget {
  const _NotificationsTable({required this.items});

  final List<AdminDashboardNotificationStats> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget cell(String text, {bool right = false, bool header = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          text,
          textAlign: right ? TextAlign.right : TextAlign.start,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: (header ? AppTextStyles.labelSm() : AppTextStyles.bodySm())
              .copyWith(
            color: header ? scheme.onSurfaceVariant : scheme.onSurface,
            fontWeight: header ? FontWeight.w600 : null,
          ),
        ),
      );
    }

    final tableRows = <List<String>>[
      ['Notification', 'Kind', 'Opens', 'Conv.', 'Rate'],
      ...items.map((n) {
        final rate = n.opens == 0
            ? '—'
            : '${(100 * n.conversionRate).toStringAsFixed(0)}%';
        final label = n.title.isNotEmpty ? n.title : n.id;
        return [label, n.kind, '${n.opens}', '${n.conversions}', rate];
      }),
    ];

    final columnWidths = _columnWidthsFor(tableRows);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        columnWidths: columnWidths,
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder(
          horizontalInside: BorderSide(color: scheme.outlineVariant),
        ),
        children: [
          for (var r = 0; r < tableRows.length; r++)
            TableRow(
              decoration: r == 0
                  ? BoxDecoration(color: scheme.surfaceContainerHighest)
                  : null,
              children: [
                for (var c = 0; c < tableRows[r].length; c++)
                  cell(
                    tableRows[r][c],
                    right: c >= 2,
                    header: r == 0,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Map<int, TableColumnWidth> _columnWidthsFor(List<List<String>> rows) {
    if (rows.isEmpty) return const {};
    final columnCount = rows.first.length;

    int maxLenForCol(int col) {
      var maxLen = 0;
      for (final r in rows) {
        if (col >= r.length) continue;
        maxLen = math.max(maxLen, r[col].length);
      }
      return maxLen;
    }

    return {
      for (var i = 0; i < columnCount; i++)
        i: i >= 2
            ? const IntrinsicColumnWidth()
            : FlexColumnWidth(math.sqrt(maxLenForCol(i).toDouble()).clamp(1, 8)),
    };
  }
}
