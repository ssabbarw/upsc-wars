import 'package:flutter/material.dart';

/// All color tokens for the app. No other file may use raw [Color] literals.
class AppColors {
  AppColors._();

  // ── Primary accent (teal-green) ──────────────────────────────────────
  static const primary = Color(0xFF1D9E75);
  static const primaryLight = Color(0xFFE1F5EE);
  static const primaryDark = Color(0xFF0F6E56);
  static const primaryDeep = Color(0xFF085041);

  // ── Semantic: correct / wrong ─────────────────────────────────────────
  static const correct = Color(0xFF1D9E75);
  static const correctBg = Color(0xFFE1F5EE);
  static const correctBgDark = Color(0xFF085041);
  static const correctText = Color(0xFF085041);
  static const correctTextDark = Color(0xFF9FE1CB);

  static const wrong = Color(0xFFE24B4A);
  static const wrongBg = Color(0xFFFCEBEB);
  static const wrongBgDark = Color(0xFF501313);
  static const wrongText = Color(0xFF791F1F);
  static const wrongTextDark = Color(0xFFF09595);

  // ── Semantic: warning / flagged ───────────────────────────────────────
  static const warning = Color(0xFFBA7517);
  static const warningBg = Color(0xFFFAEEDA);
  static const warningBgDark = Color(0xFF412402);
  static const warningText = Color(0xFF633806);
  static const warningTextDark = Color(0xFFFAC775);

  // ── Semantic: info / exam mode ────────────────────────────────────────
  static const info = Color(0xFF185FA5);
  static const infoBg = Color(0xFFE6F1FB);
  static const infoBgDark = Color(0xFF042C53);
  static const infoText = Color(0xFF0C447C);
  static const infoTextDark = Color(0xFFB5D4F4);

  // ── Accent: purple (value addition / insights) ───────────────────────
  static const purple = Color(0xFF7C5CE0);
  static const purpleBg = Color(0xFFF0ECFC);
  static const purpleBgDark = Color(0xFF2B2350);
  static const purpleText = Color(0xFF4B33A8);
  static const purpleTextDark = Color(0xFFD0C6F6);

  // ── Test series intro: gold medal + hero gradient ─────────────────────
  static const gold = Color(0xFFF2B01E);
  static const introHeroStart = Color(0xFFFFF3DC);
  static const introHeroEnd = Color(0xFFE4F5EC);
  static const introHeroStartDark = Color(0xFF3A2D12);
  static const introHeroEndDark = Color(0xFF10382C);

  // ── Neutral grays ────────────────────────────────────────────────────
  static const gray50 = Color(0xFFF1EFE8);
  static const gray100 = Color(0xFFD3D1C7);
  static const gray200 = Color(0xFFB4B2A9);
  static const gray400 = Color(0xFF888780);
  static const gray600 = Color(0xFF5F5E5A);
  static const gray800 = Color(0xFF444441);
  static const gray900 = Color(0xFF2C2C2A);

  // ── Light mode surfaces ───────────────────────────────────────────────
  static const surfacePrimaryLight = Color(0xFFFFFFFF);
  static const surfaceSecondaryLight = Color(0xFFF5F5F3);
  static const surfaceTertiaryLight = Color(0xFFEEEEEB);

  // ── Dark mode surfaces ────────────────────────────────────────────────
  static const surfacePrimaryDark = Color(0xFF1C1C1E);
  static const surfaceSecondaryDark = Color(0xFF2C2C2E);
  static const surfaceTertiaryDark = Color(0xFF3A3A3C);

  // ── Border colors ─────────────────────────────────────────────────────
  static const borderLight = Color(0x26000000);
  static const borderDark = Color(0x26FFFFFF);

  // ── Streak / fire ────────────────────────────────────────────────────
  static const streak = Color(0xFFE24B4A);

  // ── Theme text (no hex outside this file) ─────────────────────────────
  static const onSurfaceLight = Color(0xFF1C1C1E);
  static const onSurfaceVariantLight = Color(0xFF6B6B6B);
  static const onSurfaceDark = Color(0xFFEAEAEA);
  static const onSurfaceVariantDark = Color(0xFF9A9A9A);

  /// Text and icons on primary-colored controls.
  static const onPrimary = Color(0xFFFFFFFF);

  // ── Secondary / tonal ([FilledButton.tonal] uses secondaryContainer) ──
  /// Solid [info] surface with white label — matches requested brand blue.
  static const secondary = info;
  static const onSecondary = onPrimary;
  static const secondaryContainerLight = info;
  static const onSecondaryContainerLight = onPrimary;
  static const secondaryContainerDark = info;
  static const onSecondaryContainerDark = onPrimary;

  /// Session summary / marketing-style CTAs (distinct from app primary teal).
  static const summaryCtaBlue = Color(0xFF2563EB);

  /// Charts and “attempted” segments on the minimalist summary.
  static const summaryChartBlue = Color(0xFF3B82F6);

  /// Intelligent-guess tier on the minimalist session summary.
  static const summaryOrange = Color(0xFFF59E0B);

  /// Outlined secondary CTA on the minimalist session summary (light UI).
  static const summaryButtonBorder = Color(0xFFD1D5DB);
  static const summaryButtonText = Color(0xFF374151);

  /// Coach-style session summary (danger / next-action cards, light mode).
  static const coachDangerSurfaceLight = Color(0xFFFEE2E2);
  static const coachDangerBorder = Color(0xFFDC2626);
  static const coachDangerTitleText = Color(0xFF991B1B);
  static const coachDangerCtaFill = Color(0xFFDC2626);
  static const coachNextActionSurfaceLight = Color(0xFFDBEAFE);
  static const coachTrendEmerald = Color(0xFF10B981);

  /// Onboarding “latest test / hidden risk” split card (reference layout).
  static const onboardingScoreLeftPanel = Color(0xFF121212);
  static const onboardingScoreSeam = Color(0xFF2C2C2C);
  static const onboardingScoreMutedGreen = Color(0xFF76B48D);
  static const onboardingRiskPanelTop = Color(0xFF261818);
  static const onboardingRiskPanelBottom = Color(0xFF120B0B);
  static const onboardingRiskFigure = Color(0xFFD16A5E);
  static const onboardingRiskHeader = Color(0xFFCC7A6E);
  static const onboardingScoreFabFill = Color(0xFF1E1E1E);
  static const onboardingWarningBarBg = Color(0xFFF5F7F9);
  static const onboardingWarningOrange = Color(0xFFE68A45);

  static const transparent = Color(0x00000000);
}
