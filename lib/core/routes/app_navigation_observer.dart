import 'package:coffix_app/core/services/log_service.dart';
import 'package:flutter/material.dart';

class AppNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _logIfPage(route);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _logIfPage(previousRoute);
  }

  void _logIfPage(Route? route) {
    final name = route?.settings.name;
    // Only log real app page routes (named like `home_route`, `cart_route`).
    // Ignore overlay routes such as Flushbar (`/flushbarRoute`), dialogs,
    // bottom sheets, and unnamed routes.
    if (name == null || !name.endsWith('_route')) return;
    LogService().navigate(page: name);
  }
}
