import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worduno/app/routes/app_route_information_parser.dart';
import 'package:worduno/app/routes/route_paths.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppRouteInformationParser', () {
    final parser = AppRouteInformationParser();

    test('parseRouteInformation maps /dashboard to dashboard tab', () async {
      final path = await parser.parseRouteInformation(
        RouteInformation(uri: Uri.parse('/dashboard')),
      );

      expect(path.tab, AppTab.dashboard);
    });

    test('parseRouteInformation maps /study to study tab', () async {
      final path = await parser.parseRouteInformation(
        RouteInformation(uri: Uri.parse('/study')),
      );

      expect(path.tab, AppTab.study);
    });

    test('parseRouteInformation maps /profile to profile tab', () async {
      final path = await parser.parseRouteInformation(
        RouteInformation(uri: Uri.parse('/profile')),
      );

      expect(path.tab, AppTab.profile);
    });

    test('parseRouteInformation falls back to home for unknown paths', () async {
      final path = await parser.parseRouteInformation(
        RouteInformation(uri: Uri.parse('/unknown')),
      );

      expect(path.tab, AppTab.home);
    });

    test('restoreRouteInformation round-trips deep links', () {
      for (final entry in [
        (AppTab.home, '/'),
        (AppTab.study, '/study'),
        (AppTab.dashboard, '/dashboard'),
        (AppTab.profile, '/profile'),
      ]) {
        final config = AppRoutePath.initial().copyWith(tab: entry.$1);
        final info = parser.restoreRouteInformation(config);
        expect(info.uri.path, entry.$2);
      }
    });
  });
}
