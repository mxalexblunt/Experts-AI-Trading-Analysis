import 'package:flutter/cupertino.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static const _family = 'Manrope';
  static const _displayFamily = 'Manrope';

  static TextStyle get largeTitle => const TextStyle(
        inherit: false,
        fontFamily: _displayFamily,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.14,
        letterSpacing: 0,
        color: AppColors.textPrimary,
      );

  static TextStyle get title1 => const TextStyle(
        inherit: false,
        fontFamily: _displayFamily,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.18,
        letterSpacing: 0,
        color: AppColors.textPrimary,
      );

  static TextStyle get title2 => const TextStyle(
        inherit: false,
        fontFamily: _displayFamily,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.22,
        letterSpacing: 0,
        color: AppColors.textPrimary,
      );

  static TextStyle get title3 => const TextStyle(
        inherit: false,
        fontFamily: _displayFamily,
        fontSize: 21,
        fontWeight: FontWeight.w700,
        height: 1.28,
        letterSpacing: 0,
        color: AppColors.textPrimary,
      );

  static TextStyle get headline => const TextStyle(
        inherit: false,
        fontFamily: _family,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.32,
        letterSpacing: 0,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => const TextStyle(
        inherit: false,
        fontFamily: _family,
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 1.42,
        letterSpacing: 0,
        color: AppColors.textSecondary,
      );

  static TextStyle get callout => const TextStyle(
        inherit: false,
        fontFamily: _family,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.38,
        letterSpacing: 0,
        color: AppColors.textSecondary,
      );

  static TextStyle get subhead => const TextStyle(
        inherit: false,
        fontFamily: _family,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.35,
        letterSpacing: 0,
        color: AppColors.textSecondary,
      );

  static TextStyle get footnote => const TextStyle(
        inherit: false,
        fontFamily: _family,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.32,
        letterSpacing: 0,
        color: AppColors.textTertiary,
      );

  static TextStyle get caption1 => const TextStyle(
        inherit: false,
        fontFamily: _family,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.28,
        letterSpacing: 0,
        color: AppColors.textTertiary,
      );

  static TextStyle get caption2 => const TextStyle(
        inherit: false,
        fontFamily: _family,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.25,
        letterSpacing: 0,
        color: AppColors.textTertiary,
      );

  static TextStyle get button => const TextStyle(
        inherit: false,
        fontFamily: _family,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        height: 1,
        letterSpacing: 0,
        color: AppColors.onPrimary,
      );

  static TextStyle get numberLarge => const TextStyle(
        inherit: false,
        fontFamily: _displayFamily,
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1.12,
        letterSpacing: 0,
        color: AppColors.textPrimary,
        fontFeatures: [FontFeature.tabularFigures()],
      );

  static TextStyle get number => const TextStyle(
        inherit: false,
        fontFamily: _family,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0,
        color: AppColors.textPrimary,
        fontFeatures: [FontFeature.tabularFigures()],
      );
}
