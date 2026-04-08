import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography only — never set color here; apply at the widget level.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle h1() =>
      GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w500);

  static TextStyle h2() =>
      GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w500);

  static TextStyle h3() =>
      GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500);

  static TextStyle body() => GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle bodyMd() => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.55,
      );

  static TextStyle bodySm() => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle label() =>
      GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500);

  static TextStyle labelSm() =>
      GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500);

  static TextStyle caption() =>
      GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w400);

  static TextStyle question() => GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.7,
      );

  static TextStyle option() => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.55,
      );

  /// Bottom navigation labels (always visible).
  static TextStyle navLabel() =>
      GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w500);
}
