import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/coach/presentation/views/coach_pages.dart';
import '../../features/dashboard/presentation/viewmodels/dashboard_view_model.dart';
import '../../features/dashboard/presentation/views/dashboard_page.dart';
import '../../features/exam/presentation/views/exam_pages.dart';
import '../../features/home/presentation/viewmodels/level_list_view_model.dart';
import '../../features/home/presentation/views/home_page.dart';
import '../../features/home/presentation/views/level_list_page.dart';
import '../../features/home/presentation/views/term_list_page.dart';
import '../../features/home/presentation/views/unit_list_page.dart';
import '../../features/learning/presentation/views/learn_session_page.dart';
import '../../features/profile/presentation/views/profile_hub_page.dart';
import '../navigation/app_navigation_notifier.dart';
import '../shell/app_shell.dart';
import 'route_paths.dart';

class AppRouterDelegate extends RouterDelegate<AppRoutePath>
    with ChangeNotifier {
  AppRouterDelegate({required AppNavigationNotifier navigationNotifier})
      : _navigationNotifier = navigationNotifier {
    _navigationNotifier.addListener(notifyListeners);
  }

  final AppNavigationNotifier _navigationNotifier;

  @override
  void dispose() {
    _navigationNotifier.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  AppRoutePath get currentConfiguration => _navigationNotifier.configuration;

  @override
  Widget build(BuildContext context) {
    final configuration = _navigationNotifier.configuration;

    return Navigator(
      pages: [
        MaterialPage<void>(
          key: const ValueKey('app-shell'),
          child: AppShell(
            currentTab: configuration.tab,
            onTabSelected: _navigationNotifier.selectTab,
            body: _buildTabNavigator(configuration),
          ),
        ),
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        return _navigationNotifier.popActive();
      },
    );
  }

  @override
  Future<void> setNewRoutePath(AppRoutePath configuration) async {
    _navigationNotifier.selectTab(configuration.tab);
  }

  @override
  Future<bool> popRoute() async {
    return _navigationNotifier.popActive();
  }

  Widget _buildTabNavigator(AppRoutePath configuration) {
    return switch (configuration.tab) {
      AppTab.home => _buildStackNavigator(
          configuration.homeStack,
          onPop: _navigationNotifier.popHomeRoute,
        ),
      AppTab.study => _buildStackNavigator(
          configuration.studyStack,
          onPop: _navigationNotifier.popStudyRoute,
        ),
      AppTab.dashboard => ChangeNotifierProvider(
          create: (_) => DashboardViewModel(),
          child: const DashboardPage(),
        ),
      AppTab.profile => _buildProfileNavigator(configuration),
    };
  }

  Widget _buildStackNavigator(
    List<HomeStackEntry> stack, {
    required bool Function() onPop,
  }) {
    return Navigator(
      pages: [
        for (final entry in stack) _buildStackPage(entry),
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        return onPop();
      },
    );
  }

  Page<void> _buildStackPage(HomeStackEntry entry) {
    final child = switch (entry.path) {
      HomeRoutePaths.home => const HomePage(),
      HomeRoutePaths.levelList => ChangeNotifierProvider(
          create: (_) => LevelListViewModel(),
          child: const LevelListPage(),
        ),
      HomeRoutePaths.unitList => UnitListPage(
          levelCode: entry.params['level'] ?? '',
        ),
      HomeRoutePaths.termList => TermListPage(
          levelCode: entry.params['level'] ?? '',
          unitName: entry.params['unit'] ?? '',
          unitId: entry.params['unitId'],
        ),
      HomeRoutePaths.learn => LearnSessionPage(
          levelCode: entry.params['level'] ?? '',
          unitName: entry.params['unit'] ?? '',
          unitId: entry.params['unitId'],
          initialTermId: entry.params['termId'],
        ),
      HomeRoutePaths.examConfig => ExamConfigPage(
          levelCode: entry.params['level'],
          unitName: entry.params['unit'],
          unitId: entry.params['unitId'],
        ),
      HomeRoutePaths.examSession => const ExamSessionPage(),
      HomeRoutePaths.examResult => const ExamResultPage(),
      HomeRoutePaths.coachConfig => CoachConfigPage(
          levelCode: entry.params['level'],
          unitName: entry.params['unit'],
          unitId: entry.params['unitId'],
        ),
      HomeRoutePaths.coachSession => const CoachSessionPage(),
      _ => const Scaffold(
          body: Center(child: Text('Không tìm thấy trang')),
        ),
    };

    return MaterialPage<void>(
      key: ValueKey('${entry.path}:${entry.params}'),
      child: child,
    );
  }

  Widget _buildProfileNavigator(AppRoutePath configuration) {
    return switch (configuration.profileSection) {
      ProfileSection.hub => Navigator(
          pages: const [
            MaterialPage<void>(
              key: ValueKey('profile-hub'),
              child: ProfileHubPage(),
            ),
          ],
          onPopPage: (route, result) => false,
        ),
      ProfileSection.examHistory => Navigator(
          pages: [
            const MaterialPage<void>(
              key: ValueKey('exam-history-list'),
              child: ExamHistoryPage(),
            ),
            if (configuration.examDetailId != null)
              MaterialPage<void>(
                key: ValueKey('exam-detail-${configuration.examDetailId}'),
                child: ExamDetailPage(examId: configuration.examDetailId!),
              ),
          ],
          onPopPage: (route, result) {
            if (!route.didPop(result)) {
              return false;
            }
            if (configuration.examDetailId != null) {
              return _navigationNotifier.popExamDetail();
            }
            return _navigationNotifier.popProfileToHub();
          },
        ),
      ProfileSection.coachHistory => Navigator(
          pages: [
            for (final entry in configuration.coachStack)
              _buildCoachHistoryPage(entry),
          ],
          onPopPage: (route, result) {
            if (!route.didPop(result)) {
              return false;
            }
            return _navigationNotifier.popCoachRoute();
          },
        ),
    };
  }

  Page<void> _buildCoachHistoryPage(CoachStackEntry entry) {
    final child = switch (entry.path) {
      CoachRoutePaths.list => const CoachHistoryPage(),
      CoachRoutePaths.word => CoachWordHistoryPage(
          unitId: entry.params['unitId'] ?? '',
          termId: entry.params['termId'] ?? '',
        ),
      CoachRoutePaths.feedback => CoachFeedbackDetailPage(
          feedbackId: entry.params['feedbackId'] ?? '',
        ),
      CoachRoutePaths.config => CoachConfigPage(
          levelCode: entry.params['level'],
          unitName: entry.params['unit'],
          unitId: entry.params['unitId'],
        ),
      CoachRoutePaths.session => const CoachSessionPage(),
      _ => const Scaffold(
          body: Center(child: Text('Không tìm thấy trang')),
        ),
    };

    return MaterialPage<void>(
      key: ValueKey('${entry.path}:${entry.params}'),
      child: child,
    );
  }
}
