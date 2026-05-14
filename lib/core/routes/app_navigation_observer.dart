import 'package:coffix_app/core/services/log_service.dart';
import 'package:flutter/material.dart';

class AppNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    LogService().navigate(page: route.settings.name ?? '');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    LogService().navigate(page: previousRoute?.settings.name ?? '');
  }
}
