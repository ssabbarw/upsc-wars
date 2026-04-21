import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = _baseLightTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainerLight,
        onSecondaryContainer: AppColors.onSecondaryContainerLight,
        surface: AppColors.surfacePrimaryLight,
        surfaceContainerLow: AppColors.surfaceSecondaryLight,
        surfaceContainerLowest: AppColors.surfaceTertiaryLight,
        onSurface: AppColors.onSurfaceLight,
        onSurfaceVariant: AppColors.onSurfaceVariantLight,
        error: AppColors.wrong,
        onError: AppColors.onPrimary,
      ),
      scaffoldBackgroundColor: AppColors.surfaceTertiaryLight,
      textTheme: GoogleFonts.dmSansTextTheme(base).apply(
        bodyColor: AppColors.onSurfaceLight,
        displayColor: AppColors.onSurfaceLight,
      ),
      primaryTextTheme: GoogleFonts.dmSansTextTheme(base).apply(
        bodyColor: AppColors.onPrimary,
        displayColor: AppColors.onPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfacePrimaryLight,
        foregroundColor: AppColors.onSurfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceLight,
        ),
      ),
      dividerColor: AppColors.borderLight,
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 0.5,
        space: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: AppColors.transparent,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTextStyles.label(),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTextStyles.label(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurfaceLight,
          side: const BorderSide(color: AppColors.borderLight, width: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          textStyle: AppTextStyles.label(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.label(),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfacePrimaryLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.wrong, width: 0.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: AppTextStyles.bodyMd().copyWith(
          color: AppColors.onSurfaceVariantLight,
        ),
        labelStyle: AppTextStyles.labelSm().copyWith(
          color: AppColors.onSurfaceVariantLight,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.gray800,
        contentTextStyle: AppTextStyles.bodyMd().copyWith(
          color: AppColors.surfacePrimaryLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfacePrimaryLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: AppTextStyles.h2().copyWith(
          color: AppColors.onSurfaceLight,
        ),
        contentTextStyle: AppTextStyles.body().copyWith(
          color: AppColors.onSurfaceLight,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        backgroundColor: AppColors.surfacePrimaryLight,
        surfaceTintColor: AppColors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.onSurfaceVariantLight,
        textColor: AppColors.onSurfaceLight,
        titleTextStyle: AppTextStyles.label().copyWith(
          color: AppColors.onSurfaceLight,
        ),
        subtitleTextStyle: AppTextStyles.bodySm().copyWith(
          color: AppColors.onSurfaceVariantLight,
        ),
      ),
      splashFactory: InkRipple.splashFactory,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfacePrimaryLight,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariantLight,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTextStyles.navLabel(),
        unselectedLabelStyle: AppTextStyles.navLabel(),
        showUnselectedLabels: true,
      ),
    );
  }

  static ThemeData dark() {
    final base = _baseDarkTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainerDark,
        onSecondaryContainer: AppColors.onSecondaryContainerDark,
        surface: AppColors.surfacePrimaryDark,
        surfaceContainerLow: AppColors.surfaceSecondaryDark,
        surfaceContainerLowest: AppColors.surfaceTertiaryDark,
        onSurface: AppColors.onSurfaceDark,
        onSurfaceVariant: AppColors.onSurfaceVariantDark,
        error: AppColors.wrong,
        onError: AppColors.onPrimary,
      ),
      scaffoldBackgroundColor: AppColors.surfaceTertiaryDark,
      textTheme: GoogleFonts.dmSansTextTheme(base).apply(
        bodyColor: AppColors.onSurfaceDark,
        displayColor: AppColors.onSurfaceDark,
      ),
      primaryTextTheme: GoogleFonts.dmSansTextTheme(base).apply(
        bodyColor: AppColors.onPrimary,
        displayColor: AppColors.onPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfacePrimaryDark,
        foregroundColor: AppColors.onSurfaceDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceDark,
        ),
      ),
      dividerColor: AppColors.borderDark,
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 0.5,
        space: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: AppColors.transparent,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTextStyles.label(),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTextStyles.label(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurfaceDark,
          side: const BorderSide(color: AppColors.borderDark, width: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          textStyle: AppTextStyles.label(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.label(),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSecondaryDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderDark, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderDark, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.wrong, width: 0.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: AppTextStyles.bodyMd().copyWith(
          color: AppColors.onSurfaceVariantDark,
        ),
        labelStyle: AppTextStyles.labelSm().copyWith(
          color: AppColors.onSurfaceVariantDark,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceSecondaryDark,
        contentTextStyle: AppTextStyles.bodyMd().copyWith(
          color: AppColors.onSurfaceDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfacePrimaryDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: AppTextStyles.h2().copyWith(
          color: AppColors.onSurfaceDark,
        ),
        contentTextStyle: AppTextStyles.body().copyWith(
          color: AppColors.onSurfaceDark,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        backgroundColor: AppColors.surfacePrimaryDark,
        surfaceTintColor: AppColors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.onSurfaceVariantDark,
        textColor: AppColors.onSurfaceDark,
        titleTextStyle: AppTextStyles.label().copyWith(
          color: AppColors.onSurfaceDark,
        ),
        subtitleTextStyle: AppTextStyles.bodySm().copyWith(
          color: AppColors.onSurfaceVariantDark,
        ),
      ),
      splashFactory: InkRipple.splashFactory,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfacePrimaryDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariantDark,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTextStyles.navLabel(),
        unselectedLabelStyle: AppTextStyles.navLabel(),
        showUnselectedLabels: true,
      ),
    );
  }

  static TextTheme _baseLightTextTheme() {
    return TextTheme(
      displayLarge: AppTextStyles.h1(),
      displayMedium: AppTextStyles.h2(),
      displaySmall: AppTextStyles.h3(),
      headlineLarge: AppTextStyles.h1(),
      headlineMedium: AppTextStyles.h2(),
      headlineSmall: AppTextStyles.h3(),
      titleLarge: AppTextStyles.h3(),
      titleMedium: AppTextStyles.label(),
      titleSmall: AppTextStyles.labelSm(),
      bodyLarge: AppTextStyles.body(),
      bodyMedium: AppTextStyles.bodyMd(),
      bodySmall: AppTextStyles.bodySm(),
      labelLarge: AppTextStyles.label(),
      labelMedium: AppTextStyles.labelSm(),
      labelSmall: AppTextStyles.caption(),
    );
  }

  static TextTheme _baseDarkTextTheme() {
    return _baseLightTextTheme();
  }
}
