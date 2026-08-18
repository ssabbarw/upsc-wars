import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/app_language_helpers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/fomo_pulse_share.dart';
import '../domain/fomo_pulse_models.dart';
import '../fomo_pulse_constants.dart';
import '../providers/fomo_pulse_providers.dart';

class FomoPulseDetailScreen extends HookConsumerWidget {
  const FomoPulseDetailScreen({super.key, required this.pulseId});

  final String pulseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(fomoPulseDetailProvider(pulseId));
    // Opened straight from a notification there is nothing beneath this route,
    // so back should land on home rather than close the app.
    final canPop = context.canPop();

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('CA Shot'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => canPop ? context.pop() : context.go('/'),
          ),
          actions: [
            async.maybeWhen(
              data: (data) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (data.pulse.sourceUrl.isNotEmpty)
                    IconButton(
                      tooltip: 'Read source',
                      onPressed: () async {
                        final uri = Uri.tryParse(data.pulse.sourceUrl);
                        if (uri != null) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      icon: const Icon(Icons.open_in_new),
                    ),
                  IconButton(
                    tooltip: 'Share',
                    onPressed: () => unawaited(
                      shareFomoPulse(
                        data.pulse,
                        stats: data.pulse.communityStats(
                          minAttempts: FomoPulseConstants.minStatsAttempts,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.share_outlined),
                  ),
                ],
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Could not load this CA Shot.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check your internet connection and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () =>
                        ref.invalidate(fomoPulseDetailProvider(pulseId)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (data) => _PulseBody(pulse: data.pulse, attempt: data.attempt),
        ),
      ),
    );
  }
}

class _PulseBody extends HookConsumerWidget {
  const _PulseBody({required this.pulse, required this.attempt});

  final FomoPulse pulse;
  final FomoPulseAttemptState? attempt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final alreadyAttempted = attempt?.attempted == true;
    final isLaunchingMcq = useState(false);
    final showFullSummary = useState(false);
    final tabController = useTabController(initialLength: 2);

    final isHi = watchAppLanguage(ref) == 'hi';
    final summary = isHi && pulse.newsSummaryHi.trim().isNotEmpty
        ? pulse.newsSummaryHi
        : pulse.newsSummary;
    final points = isHi && pulse.upscPointsHi.isNotEmpty
        ? pulse.upscPointsHi
        : pulse.upscPoints;
    final summaryText = summary.isNotEmpty ? summary : pulse.body;

    final stats = pulse.communityStats(
      minAttempts: FomoPulseConstants.minStatsAttempts,
    );
    final question = pulse.question.localized(isHi);

    Future<void> openMcq(String? selectedOption) async {
      if (isLaunchingMcq.value) return;
      isLaunchingMcq.value = true;
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!context.mounted) return;
      await context.push(
        '/fomo-pulse/${pulse.pulseId}/mcq',
        extra: selectedOption?.toLowerCase(),
      );
      if (context.mounted) {
        isLaunchingMcq.value = false;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: _HeaderCard(
            pulse: pulse,
            summary: summaryText,
          ),
        ),
        TabBar(
          controller: tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: scheme.onSurfaceVariant,
          labelStyle: AppTextStyles.label().copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: AppTextStyles.label(),
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          dividerColor: scheme.outlineVariant.withValues(alpha: 0.45),
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: const [
            Tab(text: 'News'),
            Tab(text: 'MCQ'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                children: [
                  _SectionBlock(
                    title: 'News Summary',
                    icon: Icons.article_outlined,
                    headerColor: AppColors.primaryLight,
                    titleColor: AppColors.primaryDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _NewsImage(imageUrl: pulse.imageUrl),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          pulse.title,
                          style: AppTextStyles.label().copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          summaryText,
                          maxLines: showFullSummary.value ? null : 3,
                          overflow: showFullSummary.value
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: AppTextStyles.bodySm().copyWith(height: 1.45),
                        ),
                        if (summaryText.length > 140) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () =>
                                  showFullSummary.value = !showFullSummary.value,
                              child: Text(
                                showFullSummary.value ? 'Show less' : 'Read more',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (points.isNotEmpty) ...[
                    const _SectionDivider(),
                    _SectionBlock(
                      title: 'Why is this relevant for UPSC?',
                      icon: Icons.track_changes_outlined,
                      headerColor: const Color(0xFFF3E8FF),
                      titleColor: const Color(0xFF6D28D9),
                      child: _BulletPoints(lines: points),
                    ),
                  ],
                ],
              ),
              ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                children: [
                  if (stats != null && !alreadyAttempted) ...[
                    _SectionBlock(
                      title: 'Challenge',
                      icon: Icons.bolt_outlined,
                      headerColor: AppColors.warningBg,
                      titleColor: AppColors.warningText,
                      child: Text(
                        stats.challengeLine,
                        style: AppTextStyles.label().copyWith(
                          color: AppColors.warningText,
                        ),
                      ),
                    ),
                    const _SectionDivider(),
                  ],
                  if (pulse.isExpired && !alreadyAttempted)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Text(
                        'This CA Shot has expired.',
                        style: AppTextStyles.label().copyWith(color: scheme.error),
                      ),
                    )
                  else
                    _SectionBlock(
                      title: 'Attempt the MCQ',
                      icon: Icons.quiz_outlined,
                      headerColor: AppColors.primaryLight,
                      titleColor: AppColors.primaryDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question.stemText,
                            style: AppTextStyles.body().copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _PreviewOptionTile(
                            option: 'a',
                            text: question.optionA,
                            busy: isLaunchingMcq.value,
                            onTap: () => unawaited(openMcq('a')),
                          ),
                          _PreviewOptionTile(
                            option: 'b',
                            text: question.optionB,
                            busy: isLaunchingMcq.value,
                            onTap: () => unawaited(openMcq('b')),
                          ),
                          _PreviewOptionTile(
                            option: 'c',
                            text: question.optionC,
                            busy: isLaunchingMcq.value,
                            onTap: () => unawaited(openMcq('c')),
                          ),
                          _PreviewOptionTile(
                            option: 'd',
                            text: question.optionD,
                            busy: isLaunchingMcq.value,
                            onTap: () => unawaited(openMcq('d')),
                          ),
                          if (isLaunchingMcq.value) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Opening question...',
                              style: AppTextStyles.caption().copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ] else if (alreadyAttempted) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Tap any option to review your attempt',
                              style: AppTextStyles.caption().copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.45),
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.title,
    required this.child,
    required this.icon,
    required this.headerColor,
    required this.titleColor,
  });

  final String title;
  final Widget child;
  final IconData icon;
  final Color headerColor;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: titleColor),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.label().copyWith(
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: child,
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.pulse, required this.summary});

  final FomoPulse pulse;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sentAt = pulse.sentAt;
    final dateLabel = sentAt == null
        ? 'Today'
        : '${sentAt.day} ${_monthName(sentAt.month)} ${sentAt.year}';
    final readMins = (summary.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).length / 130)
        .ceil()
        .clamp(1, 6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pulse.title,
          style: AppTextStyles.h2().copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '$dateLabel  ·  $readMins min read  ·  High Relevance',
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _NewsImage extends StatelessWidget {
  const _NewsImage({required this.imageUrl});

  final String imageUrl;
  static const double _height = 168;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (imageUrl.trim().isEmpty) {
      return Container(
        width: double.infinity,
        height: _height,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Image.network(
        imageUrl,
        width: double.infinity,
        height: _height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: double.infinity,
          height: _height,
          color: scheme.surfaceContainerHighest,
          child: Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _BulletPoints extends StatelessWidget {
  const _BulletPoints({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          if (line.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text('• $line', style: AppTextStyles.bodySm()),
            ),
      ],
    );
  }
}

class _PreviewOptionTile extends StatelessWidget {
  const _PreviewOptionTile({
    required this.option,
    required this.text,
    required this.busy,
    this.onTap,
  });

  final String option;
  final String text;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: busy ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    option.toUpperCase(),
                    style: AppTextStyles.labelSm().copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(text, style: AppTextStyles.option())),
                if (busy)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _monthName(int month) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final i = month.clamp(1, 12) - 1;
  return months[i];
}
