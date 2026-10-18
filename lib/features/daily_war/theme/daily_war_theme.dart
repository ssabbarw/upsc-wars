import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Visual tokens from the Daily War design canvas (DM Sans · near-black card · crimson).
abstract final class DwColors {
  DwColors._();

  /// Permanently dark War surface (both app themes).
  static const surface = Color(0xFF131417);
  static const surfaceRaised = Color(0xFF1C1C1E);

  /// Signature LIVE accent — deeper than streak flame (#E24B4A).
  static const crimson = Color(0xFFC2103A);
  static const crimsonBright = Color(0xFFFF3B5C);
  static const crimsonSoft = Color(0xFFFDEBEF);

  static const onDark = Color(0xFFFFFFFF);
  static const onDarkMuted = Color(0x8CFFFFFF); // ~55%
  static const onDarkFaint = Color(0x73FFFFFF); // ~45%
  static const onDarkDim = Color(0x80FFFFFF); // ~50%

  static const ink = Color(0xFF0C0D0F);
  static const muted = Color(0xFF6B6B63);
  static const cream = Color(0xFFF5F5F3);
  static const gold = Color(0xFFC9A227);
  static const teal = Color(0xFF1D9E75);
  static const streak = Color(0xFFE24B4A);

  static const borderOnDark = Color(0x14FFFFFF); // 8%
}

abstract final class DwText {
  DwText._();

  static TextStyle dm({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = DwColors.onDark,
    double height = 1.25,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.dmSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle eyebrow({Color color = DwColors.crimsonBright}) =>
      dm(size: 10, weight: FontWeight.w700, color: color, letterSpacing: 1.4);

  static TextStyle stamp({Color color = DwColors.onDarkMuted}) =>
      dm(size: 10, weight: FontWeight.w600, color: color, letterSpacing: 0.6);

  static TextStyle subject({Color color = DwColors.onDark}) =>
      dm(size: 12, weight: FontWeight.w600, color: color, letterSpacing: 1.2);

  static TextStyle topic({Color color = DwColors.onDark}) =>
      dm(size: 23, weight: FontWeight.w700, color: color, height: 1.15);

  static TextStyle topicCompact({Color color = DwColors.onDark}) =>
      dm(size: 19, weight: FontWeight.w700, color: color, height: 1.15);

  static TextStyle heroNumber({Color color = DwColors.onDark}) => dm(
    size: 40,
    weight: FontWeight.w700,
    color: color,
    height: 1.05,
    letterSpacing: -0.5,
  );

  static TextStyle body({Color color = DwColors.onDarkMuted}) =>
      dm(size: 12, weight: FontWeight.w400, color: color);

  static TextStyle cta({Color color = DwColors.onDark}) =>
      dm(size: 14, weight: FontWeight.w700, color: color);

  static TextStyle meta({Color color = DwColors.onDarkFaint}) =>
      dm(size: 11, weight: FontWeight.w500, color: color, letterSpacing: 0.4);
}
