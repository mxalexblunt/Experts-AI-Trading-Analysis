import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/screen_logger.dart';
import 'core/theme/app_colors.dart';
import 'features/home/screens/main_tabs_screen.dart';

void main() {
  runApp(const ProviderScope(child: ExpertsApp()));
}

class ExpertsApp extends StatelessWidget {
  const ExpertsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Experts',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [ScreenLogger()],
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.canvas,
        barBackgroundColor: AppColors.canvas,
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.textPrimary,
          textStyle: TextStyle(
            inherit: false,
            fontFamily: 'Manrope',
            color: AppColors.textPrimary,
            fontSize: 17,
            letterSpacing: 0,
          ),
        ),
      ),
      home: const MainTabsScreen(),
    );
  }
}
