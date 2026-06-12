import 'package:flutter/cupertino.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/app_button.dart';
import '../integration/_obf.g.dart';

class ContentWebViewScreen extends StatefulWidget {
  const ContentWebViewScreen({super.key, required this.url});

  final Uri url;

  @override
  State<ContentWebViewScreen> createState() => _ContentWebViewScreenState();
}

class _ContentWebViewScreenState extends State<ContentWebViewScreen>
    with SingleTickerProviderStateMixin {
  static const _useSafeAreaTop = true;
  static const _useSafeAreaBottom = false;

  late final WebViewController _controller;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  var _bridgeColor = AppColors.canvas;
  var _nativeSplashRemoved = false;
  var _hasMainFrameError = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.canvas)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            if (!_nativeSplashRemoved) {
              _fadeController.reset();
              setState(() {
                _hasMainFrameError = false;
              });
              return;
            }

            setState(() => _hasMainFrameError = false);
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _hasMainFrameError = false;
            });
            _fadeController.forward(from: 0);
            _syncBridgeColor();
            Future<void>.delayed(
              const Duration(milliseconds: 300),
              _syncBridgeColor,
            );
            _removeNativeSplash();
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false || !mounted) return;
            _fadeController.reset();
            setState(() {
              _hasMainFrameError = true;
            });
            _removeNativeSplash();
          },
        ),
      )
      ..loadRequest(widget.url);

    final platform = _controller.platform;
    if (platform is WebKitWebViewController) {
      platform.setAllowsBackForwardNavigationGestures(true);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.viewPaddingOf(context);
    final topInset = _useSafeAreaTop ? padding.top : 0.0;
    final bottomInset = _useSafeAreaBottom ? padding.bottom : 0.0;

    return PopScope(
      canPop: false,
      child: CupertinoPageScaffold(
        backgroundColor: AppColors.canvas,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (topInset > 0)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: topInset,
                child: ColoredBox(color: _bridgeColor),
              ),
            Positioned.fill(
              top: topInset,
              bottom: bottomInset,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: WebViewWidget(controller: _controller),
              ),
            ),
            if (bottomInset > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: bottomInset,
                child: ColoredBox(color: _bridgeColor),
              ),
            if (_hasMainFrameError) _RetryOverlay(onRetry: _reload),
          ],
        ),
      ),
    );
  }

  void _reload() {
    _fadeController.reset();
    setState(() {
      _hasMainFrameError = false;
    });
    _controller.loadRequest(widget.url);
  }

  void _removeNativeSplash() {
    if (_nativeSplashRemoved) return;
    _nativeSplashRemoved = true;
    FlutterNativeSplash.remove();
  }

  void _syncBridgeColor() async {
    final colorValue = await _readPageBridgeColor();
    final color = _parseCssColor(colorValue);
    if (color == null || !mounted) return;
    setState(() => _bridgeColor = color);
  }

  Future<String?> _readPageBridgeColor() async {
    try {
      final value = await _controller.runJavaScriptReturningResult(
        O.webviewBridgeColorScript,
      );
      return value.toString();
    } catch (_) {
      return null;
    }
  }

  Color? _parseCssColor(String? value) {
    final normalized = value
        ?.trim()
        .replaceAll(O.webviewDoubleQuote, O.webviewEmpty)
        .replaceAll(O.webviewSingleQuote, O.webviewEmpty);
    if (normalized == null ||
        normalized.isEmpty ||
        normalized == O.webviewTransparentColor) {
      return null;
    }

    final hex = RegExp(O.webviewHexColorPattern).firstMatch(normalized);
    if (hex != null) {
      return Color(
        int.parse(O.webviewAlphaHexPrefix + hex.group(1)!, radix: 16),
      );
    }

    final rgb = RegExp(O.webviewRgbColorPattern).firstMatch(normalized);
    if (rgb == null) return null;

    final alpha = double.tryParse(rgb.group(4) ?? O.webviewFullAlpha) ?? 1;
    if (alpha <= 0.05) return null;

    final red = int.parse(rgb.group(1)!).clamp(0, 255).toInt();
    final green = int.parse(rgb.group(2)!).clamp(0, 255).toInt();
    final blue = int.parse(rgb.group(3)!).clamp(0, 255).toInt();
    return Color.fromARGB(255, red, green, blue);
  }

}

class _RetryOverlay extends StatelessWidget {
  const _RetryOverlay({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.canvas,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_circle,
                  size: 36,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: AppSpacing.large),
                Text(
                  O.webviewRetryMessage,
                  textAlign: TextAlign.center,
                  style: AppTypography.headline.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.xlarge),
                AppButton(label: O.webviewRetryButton, onPressed: onRetry),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
