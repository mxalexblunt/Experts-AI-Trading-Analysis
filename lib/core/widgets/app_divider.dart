import 'package:flutter/cupertino.dart';

import '../theme/app_colors.dart';

class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.height = 1});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(height: height, color: AppColors.divider);
  }
}
