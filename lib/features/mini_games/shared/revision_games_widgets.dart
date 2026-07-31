import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'revision_games_theme.dart';

/// Compact EN | हि control for cream games surfaces. Tap **anywhere** toggles
/// (avoids tiny per-segment hit targets). Uses [RgColors], not app ColorScheme,
/// so it stays visible on the fixed cream palette in light and dark app themes.
class RgLangToggle extends StatelessWidget {
  const RgLangToggle({
    super.key,
    required this.language,
    required this.onChanged,
    this.minHeight = 28,
  });

  final String language;
  final ValueChanged<String> onChanged;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final isHi = language == 'hi';
    final radius = BorderRadius.circular(RgRadius.sm);

    return Material(
      color: RgColors.transparent,
      child: InkWell(
        onTap: () => onChanged(isHi ? 'en' : 'hi'),
        borderRadius: radius,
        child: Ink(
          height: minHeight,
          decoration: BoxDecoration(
            color: RgColors.neutralFill,
            borderRadius: radius,
            border: Border.all(color: RgColors.border14),
          ),
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RgLangSeg(label: 'EN', selected: !isHi, left: true),
                _RgLangSeg(label: 'हि', selected: isHi, left: false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RgLangSeg extends StatelessWidget {
  const _RgLangSeg({
    required this.label,
    required this.selected,
    required this.left,
  });

  final String label;
  final bool selected;
  final bool left;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: selected ? RgColors.ink : RgColors.transparent,
        borderRadius: BorderRadius.horizontal(
          left: left ? Radius.circular(RgRadius.sm - 1) : Radius.zero,
          right: left ? Radius.zero : Radius.circular(RgRadius.sm - 1),
        ),
      ),
      child: Text(
        label,
        style: RgText.mono(
          size: 10,
          color: selected ? RgColors.onDark : RgColors.muted,
        ),
      ),
    );
  }
}

/// Cream page shell with the design's 46px white header bar and an optional
/// white footer that holds the pill CTA.
class RgGameScaffold extends StatelessWidget {
  const RgGameScaffold({
    super.key,
    required this.body,
    this.title,
    this.leadingIcon,
    this.showBack = true,
    this.centerTitle = false,
    this.trailing,
    this.footer,
  });

  final Widget body;
  final String? title;

  /// Shown instead of the back chevron (the "How to play" header uses this).
  final IconData? leadingIcon;
  final bool showBack;
  final bool centerTitle;
  final Widget? trailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RgColors.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            if (title != null)
              _RgHeader(
                title: title!,
                leadingIcon: leadingIcon,
                showBack: showBack && leadingIcon == null,
                centerTitle: centerTitle,
                trailing: trailing,
              ),
            Expanded(child: body),
            if (footer != null) RgFooterBar(child: footer!),
          ],
        ),
      ),
    );
  }
}

class _RgHeader extends StatelessWidget {
  const _RgHeader({
    required this.title,
    required this.leadingIcon,
    required this.showBack,
    required this.centerTitle,
    required this.trailing,
  });

  final String title;
  final IconData? leadingIcon;
  final bool showBack;
  final bool centerTitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(
        color: RgColors.card,
        border: Border(bottom: BorderSide(color: RgColors.border)),
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/games'),
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: RgColors.ink,
              ),
            )
          else if (leadingIcon != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(leadingIcon, size: 18, color: RgColors.ink),
            )
          else
            const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: centerTitle ? TextAlign.center : TextAlign.start,
              style: RgText.body(size: 13.5, weight: FontWeight.w700),
            ),
          ),
          if (trailing != null) ...[
            trailing!,
            const SizedBox(width: 8),
          ] else if (centerTitle && showBack)
            // Balances the back button so the title stays optically centred.
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}

/// White bar pinned under the content, hairline on top — holds the pill CTA.
class RgFooterBar extends StatelessWidget {
  const RgFooterBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: const BoxDecoration(
        color: RgColors.card,
        border: Border(top: BorderSide(color: RgColors.border)),
      ),
      child: child,
    );
  }
}

/// Full-width teal pill CTA.
class RgPillButton extends StatelessWidget {
  const RgPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fill = RgColors.teal,
    this.foreground = RgColors.onDark,
    this.verticalPadding = 12,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color fill;
  final Color foreground;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: RgText.pillButton(
          fill: fill,
          foreground: foreground,
          verticalPadding: verticalPadding,
        ),
        child: Text(label),
      ),
    );
  }
}

/// Scrollable body whose content stays vertically centred until it outgrows
/// the viewport — the `justify-content:center` bodies in the design.
class RgCenteredBody extends StatelessWidget {
  const RgCenteredBody({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
  });

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - padding.vertical,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        );
      },
    );
  }
}

/// Uppercase mono section label.
class RgMonoLabel extends StatelessWidget {
  const RgMonoLabel(
    this.text, {
    super.key,
    this.color = RgColors.mutedSoft,
    this.size = 9,
  });

  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: RgText.monoLbl(size: size, color: color),
    );
  }
}

/// Amber lightbulb chip used for every post-reveal explanation.
class RgExplanationChip extends StatelessWidget {
  const RgExplanationChip({super.key, required this.text, this.size = 11});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: RgColors.warningBg,
        borderRadius: BorderRadius.circular(RgRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 15,
            color: RgColors.warning,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: RgText.body(
                size: size,
                height: 1.5,
                color: RgColors.warningText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared end-of-session card for the four single-player games.
class RgSessionCompleteView extends StatelessWidget {
  const RgSessionCompleteView({
    super.key,
    required this.correct,
    required this.total,
    required this.onPlayAgain,
  });

  final int correct;
  final int total;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final strong = correct * 2 >= total;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RgMonoLabel('Session complete'),
            const SizedBox(height: 10),
            Text(
              '$correct / $total',
              style: RgText.display(
                size: 42,
                weight: FontWeight.w800,
                height: 1,
                color: strong ? RgColors.teal : RgColors.mutedSoft,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              strong ? 'Solid recall.' : 'Worth another pass.',
              style: RgText.body(size: 13, weight: FontWeight.w600),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: 200,
              child: RgPillButton(
                label: 'Play again',
                onPressed: onPlayAgain,
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/games'),
              style: TextButton.styleFrom(foregroundColor: RgColors.muted),
              child: Text(
                'Back to games',
                style: RgText.body(size: 13, color: RgColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
