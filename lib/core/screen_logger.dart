import 'package:flutter/cupertino.dart';

import 'services/app_log.dart';

class ScreenLogger extends NavigatorObserver {
  String _label(Route<dynamic>? route) {
    if (route == null) return '?';
    final name = route.settings.name;
    if (name != null && name != '/') return name;
    return route.runtimeType.toString();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLog.navigation('PUSH -> ${_label(route)}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLog.navigation('POP <- ${_label(route)} | back to -> ${_label(previousRoute)}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    AppLog.navigation('REPLACE ${_label(oldRoute)} -> ${_label(newRoute)}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLog.navigation('REMOVE ${_label(route)}');
  }
}
