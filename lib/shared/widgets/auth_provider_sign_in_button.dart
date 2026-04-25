import 'package:flutter/material.dart';

enum AuthProviderButtonType { google, apple }

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
      AuthProviderButtonType.google => (
        Colors.white,
        const Color(0xFF1F1F1F),
        const Color(0xFFDADCE0),
      ),
      AuthProviderButtonType.apple =>
        isDark
            ? (Colors.white, const Color(0xFF0A0A0A), const Color(0x00000000))
            : (Colors.black, Colors.white, const Color(0x00000000)),
    };

    final textStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: fg,
    );

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: effectiveOnPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Logo(type: type),
                const SizedBox(width: 10),
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
  const _Logo({required this.type});

  final AuthProviderButtonType type;

  @override
  Widget build(BuildContext context) {
    final boxSize = switch (type) {
      AuthProviderButtonType.google => 28.0,
      AuthProviderButtonType.apple => 22.0,
    };
    return SizedBox(
      width: boxSize,
      height: boxSize,
      child: Center(
        child: switch (type) {
          AuthProviderButtonType.google => Image.asset(
            'assets/logos/google_light.png',
            package: 'sign_in_button',
            height: 24,
            fit: BoxFit.contain,
          ),
          AuthProviderButtonType.apple => Icon(
            Icons.apple_rounded,
            size: 20,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.white,
          ),
        },
      ),
    );
  }
}
