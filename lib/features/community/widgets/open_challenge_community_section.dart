import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/presentation/session_subject_label.dart';
import '../../../core/presentation/user_display_name.dart';
import '../../home/providers/auth_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/tappable_circular_avatar.dart';
import '../domain/open_challenge_models.dart';
import '../open_challenge/open_challenge_create_availability.dart';
import '../providers/open_challenge_providers.dart';
import 'admin_bot_label.dart';

class OpenChallengeCommunitySection extends HookConsumerWidget {
  const OpenChallengeCommunitySection({super.key, this.highlightId});

  /// Challenge Home advertised. This list is ordered newest-first while Home
  /// ranks by how contested a challenge is, so the one they tapped can sit well
  /// down the page — mark it and bring it into view.
  final String? highlightId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final viewerEmail = ref
        .watch(authStateChangesProvider)
        .asData
        ?.value
        ?.email
        ?.toLowerCase();
    final async = ref.watch(openChallengesListProvider);
    final createAvailAsync = ref.watch(openChallengeCreateAvailabilityProvider);

    final highlightKey = useMemoized(() => GlobalKey(), [highlightId]);
    final scrolledFor = useRef<String?>(null);
    // Null when the challenge has expired or fell outside this list.
    final highlighted = highlightId != null &&
        (async.asData?.value.any((m) => m.id == highlightId) ?? false);

    useEffect(() {
      if (!highlighted || scrolledFor.value == highlightId) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = highlightKey.currentContext;
        if (target == null) return;
        scrolledFor.value = highlightId;
        unawaited(
          Scrollable.ensureVisible(
            target,
            alignment: 0.1,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          ),
        );
      });
      return null;
    }, [highlighted, highlightId]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.bolt_rounded, color: AppColors.warning, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Open challenges',
                      style: AppTextStyles.h3().copyWith(
                        color: scheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Same 10 questions — beat the room! Tap a card for the full '
                      'story.',
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              createAvailAsync.when(
                data: (OpenChallengeCreateAvailability avail) {
                  return Tooltip(
                    message: avail.allowed
                        ? 'Start a new 10-question challenge'
                        : avail.tooltipLine,
                    child: FilledButton.tonal(
                      onPressed: avail.allowed
                          ? () => context.push(
                              '/community/open-challenges/new/subject',
                            )
                          : null,
                      child: const Text('✨ Create'),
                    ),
                  );
                },
                loading: () => FilledButton.tonal(
                  onPressed: null,
                  child: const Text('✨ Create'),
                ),
                error: (_, _) => FilledButton.tonal(
                  onPressed: () =>
                      context.push('/community/open-challenges/new/subject'),
                  child: const Text('✨ Create'),
                ),
              ),
            ],
          ),
        ),
        createAvailAsync.when(
          data: (avail) {
            if (avail.allowed) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                avail.bodyCopy,
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Could not load challenges',
                  style: AppTextStyles.bodyMd(),
                ),
                const SizedBox(height: AppSpacing.xs),
                OutlinedButton(
                  onPressed: () => ref.invalidate(openChallengesListProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        Text(
                          '🎯',
                          style: AppTextStyles.h2().copyWith(fontSize: 40),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'No challenges yet — you could be first!',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.label(),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Crush a 10Q exam, then hit Create to drop a challenge '
                          'for everyone.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (final m in items) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: _ChallengeTile(
                      key: m.id == highlightId ? highlightKey : null,
                      model: m,
                      viewerEmail: viewerEmail,
                      highlighted: m.id == highlightId,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

String _liveUntilLabel(DateTime utcOrLocal) {
  final local = utcOrLocal.toLocal();
  return DateFormat('d MMM, h:mm a').format(local);
}

String _friendlyTimeAgo(DateTime? posted) {
  if (posted == null) return 'just now ✨';
  final diff = DateTime.now().difference(posted);
  if (diff.inSeconds < 60) return 'just now ✨';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({
    super.key,
    required this.model,
    required this.viewerEmail,
    this.highlighted = false,
  });

  final OpenChallengeListTileModel model;
  final String? viewerEmail;

  /// The challenge the user tapped on Home.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final my = model.myScore;
    final postedLabel = displayNameForViewer(
      name: model.postedByName,
      viewerEmail: viewerEmail,
      subjectEmail: model.postedByEmail,
    );
    final accentEnd = isDark ? AppColors.primaryDark : AppColors.primary;

    return Material(
      elevation: highlighted ? 3 : 0.5,
      shadowColor: scheme.shadow.withValues(alpha: 0.35),
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: highlighted
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => context.push('/community/open-challenges/${model.id}'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.primary, accentEnd],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TappableCircularAvatar(
                          imageUrl: model.postedByPhotoUrl,
                          displayName: postedLabel,
                          size: 52,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 2,
                                      right: AppSpacing.xs,
                                    ),
                                    child: Icon(
                                      Icons.menu_book_rounded,
                                      size: 18,
                                      color: scheme.primary,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      openChallengeSubjectTitle(model.subject),
                                      style: AppTextStyles.label().copyWith(
                                        fontSize: 16,
                                        height: 1.25,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _MetaRow(
                                icon: Icons.person_rounded,
                                text: 'by $postedLabel',
                                scheme: scheme,
                                trailing: AdminBotLabel(
                                  email: model.postedByEmail,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _MetaRow(
                                icon: Icons.schedule_rounded,
                                text: _friendlyTimeAgo(model.postedAt),
                                scheme: scheme,
                              ),
                              if (model.liveUntil != null) ...[
                                const SizedBox(height: AppSpacing.xs),
                                _MetaRow(
                                  icon: Icons.hourglass_top_rounded,
                                  text:
                                      'Live till ${_liveUntilLabel(model.liveUntil!)}',
                                  scheme: scheme,
                                ),
                              ],
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  if (highlighted)
                                    _Pill(
                                      icon: Icons.push_pin_rounded,
                                      label: 'Picked for you',
                                      background: AppColors.primary.withValues(
                                        alpha: 0.15,
                                      ),
                                      foreground: AppColors.primary,
                                    ),
                                  _Pill(
                                    icon: Icons.emoji_events_rounded,
                                    label: 'Top ${model.topScore}/10',
                                    background: isDark
                                        ? AppColors.warningBgDark.withValues(
                                            alpha: 0.45,
                                          )
                                        : AppColors.warningBg,
                                    foreground: isDark
                                        ? AppColors.warningTextDark
                                        : AppColors.warningText,
                                  ),
                                  _Pill(
                                    icon: Icons.groups_rounded,
                                    label:
                                        '${model.attemptCount} ${model.attemptCount == 1 ? 'try' : 'tries'}',
                                    background: scheme.secondaryContainer
                                        .withValues(
                                          alpha: isDark ? 0.35 : 0.65,
                                        ),
                                    foreground: scheme.onSecondaryContainer,
                                  ),
                                  if (my != null)
                                    _Pill(
                                      icon: Icons.flag_rounded,
                                      label: 'You $my/10',
                                      background: scheme.primaryContainer
                                          .withValues(alpha: 0.55),
                                      foreground: scheme.onPrimaryContainer,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.text,
    required this.scheme,
    this.trailing,
  });

  final IconData icon;
  final String text;
  final ColorScheme scheme;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
