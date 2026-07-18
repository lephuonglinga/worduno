import 'package:flutter/foundation.dart';

import '../routes/route_paths.dart';

class AppNavigationNotifier extends ChangeNotifier {
  AppRoutePath _configuration = AppRoutePath.initial();

  AppRoutePath get configuration => _configuration;

  void selectTab(AppTab tab) {
    _configuration = _configuration.copyWith(
      tab: tab,
      clearExamDetail: true,
      clearCoachStack: true,
      profileSection: ProfileSection.hub,
    );
    notifyListeners();
  }

  /// Push on the Home tab stack (shortcuts: Exam/Coach config, sessions).
  void openHomeRoute(
    String path, {
    Map<String, String> params = const {},
  }) {
    _configuration = _configuration.copyWith(
      tab: AppTab.home,
      homeStack: [
        ..._configuration.homeStack,
        HomeStackEntry(path, params),
      ],
      clearExamDetail: true,
    );
    notifyListeners();
  }

  /// Push on the Study tab stack (Level → Unit → Term → Learn/Exam/Coach).
  void openStudyRoute(
    String path, {
    Map<String, String> params = const {},
  }) {
    _configuration = _configuration.copyWith(
      tab: AppTab.study,
      studyStack: [
        ..._configuration.studyStack,
        HomeStackEntry(path, params),
      ],
      clearExamDetail: true,
    );
    notifyListeners();
  }

  /// Push on whichever stack is currently active (home or study).
  void pushActiveStackRoute(
    String path, {
    Map<String, String> params = const {},
  }) {
    if (_configuration.tab == AppTab.home) {
      openHomeRoute(path, params: params);
    } else {
      openStudyRoute(path, params: params);
    }
  }

  bool popHomeRoute() {
    if (_configuration.homeStack.length <= 1) {
      return false;
    }
    final stack = List<HomeStackEntry>.from(_configuration.homeStack)
      ..removeLast();
    _configuration = _configuration.copyWith(homeStack: stack);
    notifyListeners();
    return true;
  }

  bool popStudyRoute() {
    if (_configuration.studyStack.length <= 1) {
      return false;
    }
    final stack = List<HomeStackEntry>.from(_configuration.studyStack)
      ..removeLast();
    _configuration = _configuration.copyWith(studyStack: stack);
    notifyListeners();
    return true;
  }

  void openStudyTab() {
    selectTab(AppTab.study);
  }

  void openStudyLevel(String levelCode) {
    _configuration = _configuration.copyWith(
      tab: AppTab.study,
      studyStack: [
        const HomeStackEntry(HomeRoutePaths.levelList, {}),
        HomeStackEntry(HomeRoutePaths.unitList, {'level': levelCode}),
      ],
      clearExamDetail: true,
      clearCoachStack: true,
    );
    notifyListeners();
  }

  void openContinueLearning({
    required String levelCode,
    required String unitName,
    required String unitId,
  }) {
    _configuration = _configuration.copyWith(
      tab: AppTab.study,
      studyStack: [
        const HomeStackEntry(HomeRoutePaths.levelList, {}),
        HomeStackEntry(HomeRoutePaths.unitList, {'level': levelCode}),
        HomeStackEntry(HomeRoutePaths.termList, {
          'level': levelCode,
          'unit': unitName,
          'unitId': unitId,
        }),
      ],
      clearExamDetail: true,
      clearCoachStack: true,
    );
    notifyListeners();
  }

  void openProfileExamHistory() {
    _configuration = _configuration.copyWith(
      tab: AppTab.profile,
      profileSection: ProfileSection.examHistory,
      clearExamDetail: true,
      clearCoachStack: true,
    );
    notifyListeners();
  }

  void openProfileCoachHistory() {
    _configuration = _configuration.copyWith(
      tab: AppTab.profile,
      profileSection: ProfileSection.coachHistory,
      clearExamDetail: true,
      clearCoachStack: true,
    );
    notifyListeners();
  }

  bool popProfileToHub() {
    if (_configuration.tab != AppTab.profile) {
      return false;
    }
    if (_configuration.profileSection == ProfileSection.hub) {
      return false;
    }
    _configuration = _configuration.copyWith(
      profileSection: ProfileSection.hub,
      clearExamDetail: true,
      clearCoachStack: true,
    );
    notifyListeners();
    return true;
  }

  void openExamDetail(String examId) {
    _configuration = _configuration.copyWith(
      tab: AppTab.profile,
      profileSection: ProfileSection.examHistory,
      examDetailId: examId,
      clearCoachStack: true,
    );
    notifyListeners();
  }

  bool popExamDetail() {
    if (_configuration.examDetailId == null) {
      return false;
    }
    _configuration = _configuration.copyWith(clearExamDetail: true);
    notifyListeners();
    return true;
  }

  void _openCoachRoute(String path, Map<String, String> params) {
    _configuration = _configuration.copyWith(
      tab: AppTab.profile,
      profileSection: ProfileSection.coachHistory,
      coachStack: [
        ..._configuration.coachStack,
        CoachStackEntry(path, params),
      ],
      clearExamDetail: true,
    );
    notifyListeners();
  }

  void openCoachTermDetail({
    required String unitId,
    required String termId,
  }) {
    _openCoachRoute(CoachRoutePaths.word, {
      'unitId': unitId,
      'termId': termId,
    });
  }

  void openCoachFeedbackDetail(String feedbackId) {
    _openCoachRoute(CoachRoutePaths.feedback, {'feedbackId': feedbackId});
  }

  void resetHomeToRoot() {
    _configuration = _configuration.copyWith(
      tab: AppTab.home,
      resetHomeStack: true,
      clearExamDetail: true,
      clearCoachStack: true,
    );
    notifyListeners();
  }

  void resetStudyToRoot() {
    _configuration = _configuration.copyWith(
      tab: AppTab.study,
      resetStudyStack: true,
      clearExamDetail: true,
      clearCoachStack: true,
    );
    notifyListeners();
  }

  bool popCoachRoute() {
    if (_configuration.coachStack.length <= 1) {
      return popProfileToHub();
    }
    final stack = List<CoachStackEntry>.from(_configuration.coachStack)
      ..removeLast();
    _configuration = _configuration.copyWith(coachStack: stack);
    notifyListeners();
    return true;
  }

  void startCoachFromHistory() {
    _configuration = _configuration.copyWith(
      tab: AppTab.profile,
      profileSection: ProfileSection.coachHistory,
      coachStack: const [
        CoachStackEntry(CoachRoutePaths.list, {}),
        CoachStackEntry(CoachRoutePaths.config, {}),
      ],
      clearExamDetail: true,
    );
    notifyListeners();
  }

  void startExamFromHistory() {
    openHomeRoute(HomeRoutePaths.examConfig);
  }

  void openCoachSession() {
    if (_configuration.tab == AppTab.profile &&
        _configuration.profileSection == ProfileSection.coachHistory) {
      _openCoachRoute(CoachRoutePaths.session, const {});
      return;
    }
    if (_configuration.tab == AppTab.home) {
      openHomeRoute(HomeRoutePaths.coachSession);
      return;
    }
    openStudyRoute(HomeRoutePaths.coachSession);
  }

  void completeCoachSessionAndOpenHistory() {
    _configuration = _configuration.copyWith(
      tab: AppTab.profile,
      profileSection: ProfileSection.coachHistory,
      resetHomeStack: true,
      resetStudyStack: true,
      coachStack: const [CoachStackEntry(CoachRoutePaths.list, {})],
      clearExamDetail: true,
    );
    notifyListeners();
  }

  /// Pop the active nested stack for the current tab.
  bool popActive() {
    return switch (_configuration.tab) {
      AppTab.home => popHomeRoute(),
      AppTab.study => popStudyRoute(),
      AppTab.dashboard => false,
      AppTab.profile => _popProfile(),
    };
  }

  bool _popProfile() {
    if (_configuration.profileSection == ProfileSection.examHistory) {
      if (_configuration.examDetailId != null) {
        return popExamDetail();
      }
      return popProfileToHub();
    }
    if (_configuration.profileSection == ProfileSection.coachHistory) {
      return popCoachRoute();
    }
    return false;
  }
}
