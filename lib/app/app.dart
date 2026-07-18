import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/activity_prefs.dart';
import '../features/onboarding/presentation/views/onboarding_page.dart';
import 'navigation/app_navigation_notifier.dart';
import 'routes/app_route_information_parser.dart';
import 'routes/app_router_delegate.dart';

class WordunoApp extends StatefulWidget {
  const WordunoApp({super.key});

  @override
  State<WordunoApp> createState() => _WordunoAppState();
}

class _WordunoAppState extends State<WordunoApp> {
  late final AppNavigationNotifier _navigationNotifier;
  late final AppRouterDelegate _routerDelegate;
  late final AppRouteInformationParser _routeParser;
  bool? _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    _navigationNotifier = AppNavigationNotifier();
    _routerDelegate = AppRouterDelegate(
      navigationNotifier: _navigationNotifier,
    );
    _routeParser = AppRouteInformationParser();
    _loadOnboardingFlag();
  }

  Future<void> _loadOnboardingFlag() async {
    final seen = await ActivityPrefs.hasSeenOnboarding();
    if (!mounted) return;
    setState(() => _hasSeenOnboarding = seen);
  }

  @override
  void dispose() {
    _routerDelegate.dispose();
    _navigationNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _navigationNotifier),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerDelegate: _routerDelegate,
        routeInformationParser: _routeParser,
        builder: (context, child) {
          if (_hasSeenOnboarding == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (!_hasSeenOnboarding!) {
            return OnboardingPage(
              onFinished: () => setState(() => _hasSeenOnboarding = true),
            );
          }
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}
