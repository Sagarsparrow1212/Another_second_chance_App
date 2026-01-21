import 'package:flutter/material.dart';

class AppRoutesObserver extends NavigatorObserver {
  String? currentRoute;
  String? previousRoute;

  @override
  void didPush(Route route, Route? lastRoute) {
    previousRoute = lastRoute?.settings.name;
    currentRoute = route.settings.name;
    super.didPush(route, lastRoute);
  }

  @override
  void didPop(Route route, Route? lastRoute) {
    previousRoute = lastRoute?.settings.name;
    currentRoute = route.settings.name;
    super.didPop(route, lastRoute);
  }
}
