import 'package:flutter/material.dart';

enum AuthProviderButtonType { google, apple }

/// Official "Sign in with Google" colors from
/// https://developers.google.com/identity/branding-guidelines
abstract final class _GoogleSignInColors {
  static const lightFill = Color(0xFFFFFFFF);
  static const lightStroke = Color(0xFF747775);
  static const lightText = Color(0xFF1F1F1F);

  static const darkFill = Color(0xFF131314);
  static const darkStroke = Color(0xFF8E918F);
  static const darkText = Color(0xFFE3E3E3);
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

    final (bg, fg, border) = switch (type) {
      AuthProviderButtonType.google => isDark
          ? (
              _GoogleSignInColors.darkFill,
              _GoogleSignInColors.darkText,
              _GoogleSignInColors.darkStroke,
            )
          : (
              _GoogleSignInColors.lightFill,
              _GoogleSignInColors.lightText,
              _GoogleSignInColors.lightStroke,
            ),
      AuthProviderButtonType.apple =>
        isDark
            ? (Colors.white, const Color(0xFF0A0A0A), const Color(0x00000000))
            : (Colors.black, Colors.white, const Color(0x00000000)),
    };

    // Google: Medium 14/20. Apple keeps a slightly larger weight for parity.
    final textStyle = TextStyle(
      fontSize: type == AuthProviderButtonType.google ? 14 : 16,
      fontWeight: type == AuthProviderButtonType.google
          ? FontWeight.w500
          : FontWeight.w600,
      height: type == AuthProviderButtonType.google ? 20 / 14 : null,
      color: fg,
    );

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: effectiveOnPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Logo(type: type, googleOnDarkButton: isDark),
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
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.type, this.googleOnDarkButton = false});

  final AuthProviderButtonType type;
  final bool googleOnDarkButton;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      AuthProviderButtonType.google => _GoogleG(onDarkButton: googleOnDarkButton),
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

/// Multicolor Google "G". On dark buttons it sits on a white pad, as required
/// by Google's branding guidelines.
class _GoogleG extends StatelessWidget {
  const _GoogleG({required this.onDarkButton});

  final bool onDarkButton;

  static const _logo = AssetImage(
    'assets/logos/google_light.png',
    package: 'sign_in_button',
  );

  @override
  Widget build(BuildContext context) {
    final g = Image(image: _logo, height: 20, width: 20, fit: BoxFit.contain);
    if (!onDarkButton) {
      return SizedBox(width: 20, height: 20, child: g);
    }
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: g,
    );
  }
}
