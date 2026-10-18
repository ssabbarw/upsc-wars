import 'dart:async';

import 'package:flutter/material.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';

/// Lightweight, theme-aware toast shown via the root [Overlay].
///
/// This replaces SnackBars in the app to avoid layout shifts and to provide a
/// consistent UX across platforms.
class AppToast {
  AppToast._();

  static OverlayEntry? _entry;
  static Timer? _timer;
  static Timer? _fadeTimer;

  static void dismiss() {
    _timer?.cancel();
    _fadeTimer?.cancel();
    _timer = null;
    _fadeTimer = null;
    _entry?.remove();
    _entry = null;
  }

  static void showText(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    AppToastAction? action,
    bool top = true,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    show(
      context,
      child: Text(message),
      duration: duration,
      action: action,
      top: top,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
  }

  static void show(
    BuildContext context, {
    required Widget child,
    Duration duration = const Duration(seconds: 4),
    AppToastAction? action,
    bool top = true,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    dismiss();

    final opacity = ValueNotifier<double>(0);
    _entry = OverlayEntry(
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        final scheme = Theme.of(ctx).colorScheme;

        final topInset = media.viewPadding.top;
        final bottomInset = media.viewPadding.bottom;
        final y = top ? (topInset + 12) : null;
        final bottom = top ? null : (bottomInset + 12);

        return IgnorePointer(
          ignoring: false,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Stack(
              children: [
                Positioned(
                  left: 12,
                  right: 12,
                  top: y,
                  bottom: bottom,
                  child: ValueListenableBuilder<double>(
                    valueListenable: opacity,
                    builder: (context, value, _) {
                      return AnimatedOpacity(
                        opacity: value,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        child: _ToastCard(
                          scheme: scheme,
                          child: child,
                          action: action,
                          onDismiss: dismiss,
                          backgroundColor: backgroundColor,
                          foregroundColor: foregroundColor,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    overlay.insert(_entry!);

    // Fade in after the entry has had one frame to build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_entry == null) return;
      opacity.value = 1;
    });

    // Fade out, then remove.
    final fadeOutAt = duration - const Duration(milliseconds: 220);
    final clampedFadeOutAt = fadeOutAt.isNegative
        ? const Duration(milliseconds: 0)
        : fadeOutAt;
    _fadeTimer = Timer(clampedFadeOutAt, () => opacity.value = 0);
    _timer = Timer(duration, dismiss);
  }
}

class AppToastAction {
  const AppToastAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({
    required this.scheme,
    required this.child,
    required this.action,
    required this.onDismiss,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final ColorScheme scheme;
  final Widget child;
  final AppToastAction? action;
  final VoidCallback onDismiss;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? Colors.white;
    final textStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: fg, height: 1.25);

    final content = DefaultTextStyle(
      style: textStyle ?? const TextStyle(),
      child: IconTheme(
        data: IconThemeData(color: fg),
        child: child,
      ),
    );

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Material(
          elevation: 10,
          shadowColor: Colors.black.withValues(alpha: 0.35),
          color: backgroundColor ?? AppColors.correct,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onDismiss,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: content),
                  if (action != null) ...[
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () {
                        onDismiss();
                        action!.onPressed();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: fg,
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      child: Text(action!.label),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
