import 'package:flutter/cupertino.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_motion.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return MotionFadeSlide(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xlarge),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceInset,
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: Icon(icon, size: 26, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.small),
            Text(title, style: AppTypography.headline),
            const SizedBox(height: AppSpacing.tiny),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.footnote,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.medium),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
