import 'package:flutter/material.dart';

import 'route_paths.dart';

class AppRouteInformationParser extends RouteInformationParser<AppRoutePath> {
  @override
  Future<AppRoutePath> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final location = routeInformation.uri.path;

    switch (location) {
      case '/study':
        return AppRoutePath.initial().copyWith(tab: AppTab.study);
      case '/dashboard':
        return AppRoutePath.initial().copyWith(tab: AppTab.dashboard);
      case '/profile':
        return AppRoutePath.initial().copyWith(tab: AppTab.profile);
      default:
        return AppRoutePath.initial();
    }
  }

  @override
  RouteInformation restoreRouteInformation(AppRoutePath configuration) {
    final location = switch (configuration.tab) {
      AppTab.home => '/',
      AppTab.study => '/study',
      AppTab.dashboard => '/dashboard',
      AppTab.profile => '/profile',
    };

    return RouteInformation(uri: Uri.parse(location));
  }
}
