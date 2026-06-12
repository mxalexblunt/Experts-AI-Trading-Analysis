import 'package:flutter/foundation.dart';

abstract final class AppLog {
  static const bool aiEnabled = bool.fromEnvironment(
    'EXPERTS_AI_LOGS',
    defaultValue: true,
  );
  static const bool navigationEnabled = bool.fromEnvironment(
    'EXPERTS_NAV_LOGS',
  );
  static const bool assetLogoEnabled = bool.fromEnvironment(
    'EXPERTS_ASSET_LOGS',
  );

  static void ai(String message, {Object? error, StackTrace? stackTrace}) {
    _write('AI', message, enabled: aiEnabled, error: error, stackTrace: stackTrace);
  }

  static void navigation(String message) {
    _write('NAV', message, enabled: navigationEnabled);
  }

  static void assetLogo(String message, {Object? error}) {
    _write('ASSET_LOGO', message, enabled: assetLogoEnabled, error: error);
  }

  static String describeError(Object error) {
    return _oneLine(error.toString());
  }

  static String preview(String value, {int maxLength = 700}) {
    final oneLine = _oneLine(value);
    if (oneLine.length <= maxLength) return oneLine;
    return '${oneLine.substring(0, maxLength)}...';
  }

  static void _write(
    String tag,
    String message, {
    required bool enabled,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode || !enabled) return;
    debugPrint('[$tag] ${_oneLine(message)}');
    if (error != null) {
      debugPrint('[$tag] error=${describeError(error)}');
    }
    if (stackTrace != null) {
      final frames = stackTrace.toString().split('\n').take(8).join('\n');
      debugPrint('[$tag] stack=$frames');
    }
  }

  static String _oneLine(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
