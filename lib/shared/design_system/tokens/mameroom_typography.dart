import 'package:flutter/material.dart';

import 'mameroom_colors.dart';

class MameroomTypography {
  const MameroomTypography._();

  static const fontFamily = 'Pretendard';
  static const fallbackFonts = ['Noto Sans KR', 'sans-serif'];

  static const displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fallbackFonts,
    fontSize: 32,
    height: 1.18,
    fontWeight: FontWeight.w700,
    color: MameroomColors.textPrimary,
  );

  static const titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fallbackFonts,
    fontSize: 20,
    height: 1.28,
    fontWeight: FontWeight.w700,
    color: MameroomColors.textPrimary,
  );

  static const titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fallbackFonts,
    fontSize: 18,
    height: 1.34,
    fontWeight: FontWeight.w600,
    color: MameroomColors.textPrimary,
  );

  static const bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fallbackFonts,
    fontSize: 16,
    height: 1.6,
    fontWeight: FontWeight.w500,
    color: MameroomColors.textPrimary,
  );

  static const bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fallbackFonts,
    fontSize: 14,
    height: 1.6,
    fontWeight: FontWeight.w400,
    color: MameroomColors.textSecondary,
  );

  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fallbackFonts,
    fontSize: 12,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: MameroomColors.textMuted,
  );

  static const button = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fallbackFonts,
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );

  static TextTheme get textTheme => const TextTheme(
    displayLarge: displayLarge,
    headlineLarge: displayLarge,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    labelSmall: caption,
    labelLarge: button,
  );
}
