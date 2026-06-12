import 'package:flutter/cupertino.dart';

import 'app_colors.dart';

abstract final class AppShadows {
  static List<BoxShadow> get subtle => [
        BoxShadow(
          color: AppColors.shadow.withValues(alpha: 0.05),
          offset: const Offset(0, 5),
          blurRadius: 18,
          spreadRadius: -8,
        ),
      ];

  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.shadow.withValues(alpha: 0.09),
          offset: const Offset(0, 18),
          blurRadius: 42,
          spreadRadius: -18,
        ),
      ];

  static List<BoxShadow> get floating => [
        BoxShadow(
          color: AppColors.shadow.withValues(alpha: 0.16),
          offset: const Offset(0, 24),
          blurRadius: 54,
          spreadRadius: -22,
        ),
      ];

  static List<BoxShadow> get control => [
        BoxShadow(
          color: AppColors.shadow.withValues(alpha: 0.10),
          offset: const Offset(0, 10),
          blurRadius: 28,
          spreadRadius: -14,
        ),
      ];
}
