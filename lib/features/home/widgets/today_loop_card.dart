import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// How a daily loop is painted on home.
enum TodayLoopLayout {
  /// Full-width ritual — the one to do now.
  hero,

  /// Half of a two-up row under the hero.
  tile,

  /// Full-width slim strip when only one companion is on.
  banner,
}

/// Shared chrome for CA, drill, week review, and compact War.
class TodayLoopCard extends StatelessWidget {
  const TodayLoopCard({
    super.key,
    required this.layout,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.icon,
    required this.accent,
    required this.background,
    required this.onTap,
    this.done = false,
    this.loading = false,
    this.showNow = false,
    this.foreground,
    this.mutedForeground,
    this.footer,
    this.actions,
    this.titleMaxLines,
  });

  final TodayLoopLayout layout;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String cta;
  final IconData icon;
  final Color accent;
  final Color background;
  final VoidCallback? onTap;
  final bool done;
  final bool loading;
  final bool showNow;
  final Color? foreground;
  final Color? mutedForeground;
  final Widget? footer;

  /// Replaces the hero CTA pill when set (e.g. missed vs saved).
  final Widget? actions;

  /// Overrides the layout default so long titles (two War topics) can wrap.
  final int? titleMaxLines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = foreground ?? scheme.onSurface;
    final muted = mutedForeground ?? scheme.onSurfaceVariant;
    final border = done
        ? accent.withValues(alpha: 0.4)
        : (isDark ? AppColors.borderDark : AppColors.borderLight);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: layout == TodayLoopLayout.hero ? accent : border,
              width: layout == TodayLoopLayout.hero ? 1.6 : 0.8,
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  layout == TodayLoopLayout.tile ? AppSpacing.md : AppSpacing.lg,
                  layout == TodayLoopLayout.tile ? AppSpacing.md : AppSpacing.lg,
                  showNow
                      ? 52
                      : (layout == TodayLoopLayout.tile
                          ? AppSpacing.md
                          : AppSpacing.lg),
                  layout == TodayLoopLayout.tile ? AppSpacing.md : AppSpacing.lg,
                ),
                child: switch (layout) {
                  TodayLoopLayout.hero => _HeroBody(
                      eyebrow: eyebrow,
                      title: title,
                      subtitle: subtitle,
                      cta: cta,
                      icon: icon,
                      accent: accent,
                      fg: fg,
                      muted: muted,
                      done: done,
                      loading: loading,
                      footer: footer,
                      actions: actions,
                      titleMaxLines: titleMaxLines ?? 2,
                    ),
                  TodayLoopLayout.tile => _TileBody(
                      eyebrow: eyebrow,
                      title: title,
                      subtitle: subtitle,
                      cta: cta,
                      icon: icon,
                      accent: accent,
                      fg: fg,
                      muted: muted,
                      done: done,
                      loading: loading,
                      titleMaxLines: titleMaxLines ?? 1,
                    ),
                  TodayLoopLayout.banner => _BannerBody(
                      eyebrow: eyebrow,
                      title: title,
                      subtitle: subtitle,
                      cta: cta,
                      icon: icon,
                      accent: accent,
                      fg: fg,
                      muted: muted,
                      done: done,
                      loading: loading,
                      titleMaxLines: titleMaxLines ?? 1,
                    ),
                },
              ),
              if (showNow)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: _NowBadge(color: accent),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NowBadge extends StatelessWidget {
  const _NowBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'NOW',
        style: AppTextStyles.caption().copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _IconMark extends StatelessWidget {
  const _IconMark({
    required this.icon,
    required this.accent,
    required this.done,
    this.size = 44,
  });

  final IconData icon;
  final Color accent;
  final bool done;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(
        done ? Icons.check_rounded : icon,
        color: accent,
        size: size < 40 ? 20 : 24,
      ),
    );
  }
}

class _HeroBody extends StatelessWidget {
  const _HeroBody({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.icon,
    required this.accent,
    required this.fg,
    required this.muted,
    required this.done,
    required this.loading,
    this.footer,
    this.actions,
    this.titleMaxLines = 2,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String cta;
  final IconData icon;
  final Color accent;
  final Color fg;
  final Color muted;
  final bool done;
  final bool loading;
  final Widget? footer;
  final Widget? actions;
  final int titleMaxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconMark(icon: icon, accent: accent, done: done),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: AppTextStyles.caption().copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.9,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: titleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h2().copyWith(
                      fontWeight: FontWeight.w700,
                      color: fg,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            if (loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySm().copyWith(color: muted, height: 1.45),
        ),
        const SizedBox(height: AppSpacing.md),
        if (actions != null)
          actions!
        else
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  cta,
                  style: AppTextStyles.labelSm().copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (footer != null) ...[
                const Spacer(),
                footer!,
              ],
            ],
          ),
      ],
    );
  }
}

class _TileBody extends StatelessWidget {
  const _TileBody({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.icon,
    required this.accent,
    required this.fg,
    required this.muted,
    required this.done,
    required this.loading,
    this.titleMaxLines = 1,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String cta;
  final IconData icon;
  final Color accent;
  final Color fg;
  final Color muted;
  final bool done;
  final bool loading;
  final int titleMaxLines;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconMark(icon: icon, accent: accent, done: done, size: 36),
              const Spacer(),
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            eyebrow,
            style: AppTextStyles.caption().copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: titleMaxLines,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMd().copyWith(
              fontWeight: FontWeight.w700,
              color: fg,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption().copyWith(
                color: muted,
                height: 1.3,
              ),
            ),
          ),
          Text(
            cta,
            style: AppTextStyles.labelSm().copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerBody extends StatelessWidget {
  const _BannerBody({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.icon,
    required this.accent,
    required this.fg,
    required this.muted,
    required this.done,
    required this.loading,
    this.titleMaxLines = 1,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String cta;
  final IconData icon;
  final Color accent;
  final Color fg;
  final Color muted;
  final bool done;
  final bool loading;
  final int titleMaxLines;

  @override
  Widget build(BuildContext context) {
    final ctaWidget = loading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(
            cta,
            style: AppTextStyles.labelSm().copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          );
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: AppTextStyles.caption().copyWith(
            color: accent,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          maxLines: titleMaxLines,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMd().copyWith(
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption().copyWith(color: muted),
        ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconMark(icon: icon, accent: accent, done: done),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: titleMaxLines > 1
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: AppSpacing.sm),
                    ctaWidget,
                  ],
                )
              : titleBlock,
        ),
        if (titleMaxLines <= 1) ...[
          const SizedBox(width: AppSpacing.sm),
          ctaWidget,
        ],
      ],
    );
  }
}
