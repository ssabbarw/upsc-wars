import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Games-scoped design tokens for the "Revision Games v2" surfaces.
///
/// These deliberately sit outside the app-wide `AppColors` / `AppTextStyles`:
/// the games hub and the six mini-games render in a fixed cream/teal palette in
/// both app themes, so nothing here should leak into the rest of the app.
class RgColors {
  RgColors._();

  // ── Surfaces ─────────────────────────────────────────────────────────
  static const pageBg = Color(0xFFF5F0E8);
  static const card = Color(0xFFFFFFFF);
  static const neutralFill = Color(0xFFF1EFE8);

  // ── Ink ──────────────────────────────────────────────────────────────
  static const ink = Color(0xFF1C1C1E);
  static const muted = Color(0xFF6B6B63);
  static const mutedSoft = Color(0xFF8A8578);
  static const onDark = Color(0xFFFFFFFF);
  static const dragHandle = Color(0xFFC9C6BA);

  // ── Teal (primary CTA) ───────────────────────────────────────────────
  static const teal = Color(0xFF1A7A5E);
  static const tealDeep = Color(0xFF0F6E56);
  static const correctBg = Color(0xFFE1F5EE);
  static const correctBorder = Color(0x4D1D9E75);

  // ── Wrong / lockout ──────────────────────────────────────────────────
  static const wrong = Color(0xFFE24B4A);
  static const wrongBg = Color(0xFFFCE9E8);
  static const wrongText = Color(0xFF8F2C2B);
  static const wrongBorder = Color(0x59E24B4A);

  // ── Warning / amber ──────────────────────────────────────────────────
  static const warning = Color(0xFFBA7517);
  static const warningBg = Color(0xFFFAEEDA);
  static const warningText = Color(0xFF633806);
  static const warningBorder = Color(0x4DBA7517);

  // ── Info blue ────────────────────────────────────────────────────────
  static const info = Color(0xFF185FA5);

  // ── Hairlines and washes ─────────────────────────────────────────────
  static const border = Color(0x1A000000);
  static const border12 = Color(0x1F000000);
  static const border14 = Color(0x24000000);
  static const stampNeutralBg = Color(0x14000000);
  static const scrim = Color(0x73000000);
  static const transparent = Color(0x00000000);
}

/// Corner radii used across the games surfaces.
class RgRadius {
  RgRadius._();

  static const double sm = 10;
  static const double md = 12;
  static const double lg = 14;
  static const double xl = 16;
  static const double pill = 100;
}

/// Type ramp: DM Sans for body, Bricolage Grotesque for display titles,
/// IBM Plex Mono for labels, scores and stamps.
class RgText {
  RgText._();

  /// Bricolage Grotesque — question prompts, screen titles, big scores.
  static TextStyle display({
    double size = 16,
    FontWeight weight = FontWeight.w700,
    double? height,
    Color color = RgColors.ink,
  }) {
    return GoogleFonts.bricolageGrotesque(
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color,
    );
  }

  /// DM Sans — everything conversational.
  static TextStyle body({
    double size = 12.5,
    FontWeight weight = FontWeight.w400,
    double? height,
    Color color = RgColors.ink,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.dmSans(
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color,
      decoration: decoration,
      decorationColor: color,
    );
  }

  /// IBM Plex Mono — scores, stamps, badges.
  static TextStyle mono({
    double size = 11,
    FontWeight weight = FontWeight.w700,
    double letterSpacingEm = 0,
    double? height,
    Color color = RgColors.ink,
  }) {
    return GoogleFonts.ibmPlexMono(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: size * letterSpacingEm,
      height: height,
      color: color,
    );
  }

  /// The uppercase micro-label that heads most sections.
  static TextStyle monoLbl({
    double size = 9,
    FontWeight weight = FontWeight.w600,
    Color color = RgColors.mutedSoft,
  }) {
    return mono(
      size: size,
      weight: weight,
      letterSpacingEm: 0.08,
      color: color,
    );
  }

  /// Filled pill CTA — teal fill, white DM Sans w700 label.
  static ButtonStyle pillButton({
    Color fill = RgColors.teal,
    Color foreground = RgColors.onDark,
    double verticalPadding = 13,
  }) {
    return FilledButton.styleFrom(
      backgroundColor: fill,
      foregroundColor: foreground,
      disabledBackgroundColor: fill,
      disabledForegroundColor: foreground,
      elevation: 0,
      shape: const StadiumBorder(),
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      textStyle: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
