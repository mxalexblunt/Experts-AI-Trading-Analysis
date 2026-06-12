import 'package:flutter/cupertino.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/screen_logger.dart';
import 'core/theme/app_colors.dart';
import 'features/home/screens/main_tabs_screen.dart';
import 'webview/content_webview_screen.dart';
import 'webview/startup_content_service.dart';

void main() {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
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
      home: const StartupGate(),
    );
  }
}

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late final Future<StartupContentDecision> _startupDecision;
  var _nativeSplashRemoved = false;

  @override
  void initState() {
    super.initState();
    _startupDecision = const StartupContentService().resolve();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StartupContentDecision>(
      future: _startupDecision,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CupertinoPageScaffold(
            backgroundColor: AppColors.canvas,
            child: Center(
              child: CupertinoActivityIndicator(
                radius: 14,
                color: AppColors.textPrimary,
              ),
            ),
          );
        }

        final startupUrl = snapshot.data?.url;
        if (startupUrl != null) {
          return ContentWebViewScreen(url: startupUrl);
        }

        _removeNativeSplash();
        return const MainTabsScreen();
      },
    );
  }

  void _removeNativeSplash() {
    if (_nativeSplashRemoved) return;
    _nativeSplashRemoved = true;
    FlutterNativeSplash.remove();
  }
}
