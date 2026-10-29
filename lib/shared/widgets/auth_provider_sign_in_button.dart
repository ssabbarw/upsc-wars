import 'package:flutter/material.dart';

enum AuthProviderButtonType { google, apple }

/// Colored Google button. Blue stays distinct on both light and dark surfaces;
/// the dark fill is the lighter Google blue so it doesn't sink into a black page.
abstract final class _GoogleSignInColors {
  static const lightFill = Color(0xFF1A73E8);
  static const lightText = Color(0xFFFFFFFF);

  static const darkFill = Color(0xFF8AB4F8);
  static const darkText = Color(0xFF202124);
}

class AuthProviderSignInButton extends StatelessWidget {
  const AuthProviderSignInButton({
    super.key,
    required this.type,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.height = 48,
    this.borderRadius = 10,
  });

  final AuthProviderButtonType type;
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveOnPressed = (isLoading) ? null : onPressed;

    final (bg, fg) = switch (type) {
      AuthProviderButtonType.google =>
        isDark
            ? (_GoogleSignInColors.darkFill, _GoogleSignInColors.darkText)
            : (_GoogleSignInColors.lightFill, _GoogleSignInColors.lightText),
      AuthProviderButtonType.apple =>
        isDark
            ? (Colors.white, const Color(0xFF0A0A0A))
            : (Colors.black, Colors.white),
    };

    final textStyle = TextStyle(
      fontSize: type == AuthProviderButtonType.google ? 15 : 16,
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: fg,
    );

    final dimmed = effectiveOnPressed == null && !isLoading;

    return Opacity(
      opacity: dimmed ? 0.5 : 1,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: effectiveOnPressed,
            splashColor: fg.withValues(alpha: 0.16),
            highlightColor: fg.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Logo(type: type),
                  const SizedBox(width: 12),
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: isLoading
                          ? SizedBox(
                              key: const ValueKey('loading'),
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: fg.withValues(alpha: 0.85),
                              ),
                            )
                          : Text(
                              text,
                              key: const ValueKey('text'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textStyle,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.type});

  final AuthProviderButtonType type;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      AuthProviderButtonType.google => const _GoogleG(),
      AuthProviderButtonType.apple => SizedBox(
        width: 22,
        height: 22,
        child: Icon(
          Icons.apple_rounded,
          size: 20,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
        ),
      ),
    };
  }
}

/// Multicolor Google "G". The packaged asset is a small mark centered on a
/// white plate, so the plate is cropped and the G is scaled up to button size.
class _GoogleG extends StatelessWidget {
  const _GoogleG();

  static const _logo = AssetImage(
    'assets/logos/google_light.png',
    package: 'sign_in_button',
  );

  static const _markSize = 25.0;

  /// Source canvas is 48px; the colored G sits in the center ~18px.
  static const _zoom = _markSize * (48 / 22);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: _markSize,
        height: _markSize,
        child: const OverflowBox(
          maxWidth: _zoom,
          maxHeight: _zoom,
          child: Image(
            image: _logo,
            width: _zoom,
            height: _zoom,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}
