import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/providers/app_language_helpers.dart';
import '../../home/domain/daily_rituals.dart';
import '../../../core/providers/super_user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/en_hi_language_toggle.dart';
import '../data/fomo_pulse_cloud_service.dart';
import '../domain/fomo_pulse_models.dart';
import '../fomo_pulse_constants.dart';
import '../providers/fomo_pulse_providers.dart';

class FomoPulseHistoryScreen extends HookConsumerWidget {
  const FomoPulseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(fomoPulseHistoryProvider);
    final scheme = Theme.of(context).colorScheme;
    final prefsLang = watchAppLanguage(ref);
    final langOverride = useState<String?>(null);
    final uiLang = normalizeAppLanguage(langOverride.value ?? prefsLang);
    final preferHindi = uiLang == 'hi';
    final loggedHubOpen = useRef(false);
    final isAdmin = ref.watch(isSuperUserProvider);
    final hiddenIds = useState<Set<String>>(const {});

    useEffect(() {
      if (loggedHubOpen.value || async.isLoading) return null;
      loggedHubOpen.value = true;
      final data = async.asData?.value;
      unawaited(markDailyRitualOpened(ref, DailyRitualIds.caShots));
      unawaited(
        Analytics.track(
          ref,
          CaShotHubOpenedEvent(
            shotCount: data?.pulses.length ?? 0,
            doneCount:
                data?.attempts.values.where((a) => a.attempted).length ?? 0,
          ),
        ),
      );
      return null;
    }, [async]);

    void leaveList() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        leaveList();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('CA Shots'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: leaveList,
          ),
          actions: [
            TextButton.icon(
              onPressed: () => _showWhatIsCaShotsSheet(context),
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text("What's this?"),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: EnHiLanguageToggle(
                  language: uiLang,
                  onChanged: (lang) {
                    langOverride.value = lang;
                    unawaited(persistAppLanguage(ref, lang));
                  },
                ),
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (data) {
                  final pulses = [
                    for (final p in data.pulses)
                      if (!hiddenIds.value.contains(p.pulseId)) p,
                  ];
                  if (pulses.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          'No CA Shots yet. Breaking CA briefings will show up here.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySm().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }
                  final sections = _groupByDate(pulses);
                  return RefreshIndicator(
                    onRefresh: () async {
                      hiddenIds.value = const {};
                      await ref
                          .read(fomoPulseRepositoryProvider)
                          .loadHistory(forceRefresh: true);
                      ref.invalidate(fomoPulseHistoryProvider);
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      itemCount: sections.length,
                      itemBuilder: (context, sectionIndex) {
                        final section = sections[sectionIndex];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: sectionIndex == sections.length - 1
                                ? 0
                                : AppSpacing.lg,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section.label,
                                style: AppTextStyles.label().copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              for (var i = 0; i < section.pulses.length; i++) ...[
                                _historyTile(
                                  context: context,
                                  ref: ref,
                                  pulse: section.pulses[i],
                                  attempt:
                                      data.attempts[section.pulses[i].pulseId],
                                  preferHindi: preferHindi,
                                  isAdmin: isAdmin,
                                  onDeleted: (pulseId) {
                                    hiddenIds.value = {
                                      ...hiddenIds.value,
                                      pulseId,
                                    };
                                  },
                                ),
                                if (i != section.pulses.length - 1)
                                  const SizedBox(height: AppSpacing.sm),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _historyTile({
  required BuildContext context,
  required WidgetRef ref,
  required FomoPulse pulse,
  required FomoPulseAttemptState? attempt,
  required bool preferHindi,
  required bool isAdmin,
  required ValueChanged<String> onDeleted,
}) {
  final tile = _PulseHistoryTile(
    pulse: pulse,
    attempt: attempt,
    preferHindi: preferHindi,
    showZeroAttempts: isAdmin,
    onTap: () => context.push(
      FomoPulseConstants.detailLocation(
        pulse.pulseId,
        source: FomoPulseConstants.entryHistory,
      ),
    ),
  );
  if (!isAdmin) return tile;

  final scheme = Theme.of(context).colorScheme;
  return Dismissible(
    key: ValueKey(pulse.pulseId),
    direction: DismissDirection.horizontal,
    background: _deleteSwipeBackground(scheme, Alignment.centerLeft),
    secondaryBackground: _deleteSwipeBackground(scheme, Alignment.centerRight),
    confirmDismiss: (_) => _confirmDeletePulse(context, ref, pulse),
    onDismissed: (_) {
      onDeleted(pulse.pulseId);
      ref.invalidate(fomoPulseDetailProvider(pulse.pulseId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CA Shot deleted for everyone.')),
      );
    },
    child: tile,
  );
}

Widget _deleteSwipeBackground(ColorScheme scheme, Alignment alignment) {
  return Container(
    alignment: alignment,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    decoration: BoxDecoration(
      color: scheme.error,
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Icon(Icons.delete_outline, color: scheme.onError),
  );
}

Future<bool> _confirmDeletePulse(
  BuildContext context,
  WidgetRef ref,
  FomoPulse pulse,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => _DeletePulseConfirmDialog(
      onDelete: () async {
        await ref
            .read(fomoPulseCloudServiceProvider)
            .deletePulse(pulse.pulseId);
        await ref
            .read(fomoPulseRepositoryProvider)
            .removePulseFromCache(pulse.pulseId);
      },
    ),
  );
  return ok == true;
}

class _DeletePulseConfirmDialog extends StatefulWidget {
  const _DeletePulseConfirmDialog({required this.onDelete});

  final Future<void> Function() onDelete;

  @override
  State<_DeletePulseConfirmDialog> createState() =>
      _DeletePulseConfirmDialogState();
}

class _DeletePulseConfirmDialogState extends State<_DeletePulseConfirmDialog> {
  var _busy = false;
  String? _error;

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onDelete();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = FomoPulseCloudService.describeCallableError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: const Text('Delete CA Shot?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This removes it for everyone. It will disappear from CA Shots and new attempts will be blocked.',
            ),
            if (_busy) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Deleting for everyone…',
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: AppTextStyles.bodySm().copyWith(color: scheme.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              minimumSize: const Size(64, 40),
            ),
            onPressed: _submit,
            child: _busy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onError,
                    ),
                  )
                : const Text('Delete for everyone'),
          ),
        ],
      ),
    );
  }
}

void _showWhatIsCaShotsSheet(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What are CA Shots?',
                style: AppTextStyles.h3().copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Think of these as short daily drills — shots you can take every day to prepare for your final battle.',
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ExplainerRow(
                icon: Icons.notifications_active_outlined,
                title: 'Frequent alerts',
                body:
                    'You get notified when a UPSC-relevant article is worth your attention.',
              ),
              const SizedBox(height: AppSpacing.md),
              _ExplainerRow(
                icon: Icons.quiz_outlined,
                title: 'One focused MCQ',
                body:
                    'Each shot gives one concept-based MCQ from that article, with explanation.',
              ),
              const SizedBox(height: AppSpacing.md),
              _ExplainerRow(
                icon: Icons.shield_outlined,
                title: 'Battle readiness',
                body:
                    'Take these shots daily so your concepts stay sharp for the final battle.',
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ExplainerRow extends StatelessWidget {
  const _ExplainerRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 18, color: scheme.onPrimaryContainer),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.label().copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PulseHistoryTile extends StatelessWidget {
  const _PulseHistoryTile({
    required this.pulse,
    required this.attempt,
    required this.preferHindi,
    required this.onTap,
    this.showZeroAttempts = false,
  });

  final FomoPulse pulse;
  final FomoPulseAttemptState? attempt;
  final bool preferHindi;
  final VoidCallback onTap;
  final bool showZeroAttempts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final attempted = attempt?.attempted == true;
    final date = pulse.sentAt;
    final dateLabel = date != null
        ? DateFormat('d MMM · h:mm a').format(date.toLocal())
        : '';
    final title = pulse.listTitle(preferHindi: preferHindi);
    final body = pulse.listBody(preferHindi: preferHindi);

    final (badgeBg, badgeFg, badgeLabel) = !attempted
        ? (scheme.surfaceContainerHighest, scheme.onSurfaceVariant, 'Not done')
        : attempt!.isCorrect
        ? (
            isDark ? AppColors.correctBgDark : AppColors.correctBg,
            isDark ? AppColors.correctTextDark : AppColors.correctText,
            'Done · Correct',
          )
        : (
            isDark ? AppColors.wrongBgDark : AppColors.wrongBg,
            isDark ? AppColors.wrongTextDark : AppColors.wrongText,
            'Done · Wrong',
          );

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PulseThumbnail(pulse: pulse),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label().copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (body.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (dateLabel.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dateLabel,
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        badgeLabel,
                        style: AppTextStyles.caption().copyWith(
                          color: badgeFg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (showZeroAttempts || pulse.attemptCount > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  pulse.communityCounts.breakdownLine,
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseThumbnail extends StatelessWidget {
  const _PulseThumbnail({required this.pulse});

  final FomoPulse pulse;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = pulse.imageUrl.trim();
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: scheme.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? Icon(Icons.image_outlined, color: scheme.onSurfaceVariant)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.broken_image_outlined,
                color: scheme.onSurfaceVariant,
              ),
            ),
    );
  }
}

class _HistorySection {
  const _HistorySection({required this.label, required this.pulses});

  final String label;
  final List<FomoPulse> pulses;
}

List<_HistorySection> _groupByDate(List<FomoPulse> pulses) {
  final groups = <String, List<FomoPulse>>{};
  for (final p in pulses) {
    final local = p.sentAt?.toLocal();
    final key = local == null
        ? 'undated'
        : DateFormat('yyyy-MM-dd').format(local);
    groups.putIfAbsent(key, () => []).add(p);
  }
  final keys = groups.keys.toList()
    ..sort((a, b) {
      if (a == 'undated') return 1;
      if (b == 'undated') return -1;
      return b.compareTo(a);
    });
  return [
    for (final key in keys)
      _HistorySection(
        label: key == 'undated'
            ? 'Undated'
            : DateFormat('EEE, d MMM').format(DateTime.parse(key)),
        pulses: groups[key]!,
      ),
  ];
}
