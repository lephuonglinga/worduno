enum AppTab {
  home,
  study,
  dashboard,
  profile,
}

enum ProfileSection {
  hub,
  examHistory,
  coachHistory,
}

class HomeRoutePaths {
  HomeRoutePaths._();

  /// Home tab root (gateway).
  static const home = '/home';

  /// Study tab root + nested learning routes.
  static const levelList = '/';
  static const unitList = '/units';
  static const termList = '/terms';
  static const learn = '/learn';
  static const examConfig = '/exam/config';
  static const examSession = '/exam/session';
  static const examResult = '/exam/result';
  static const coachConfig = '/coach/config';
  static const coachSession = '/coach/session';
}

class CoachRoutePaths {
  CoachRoutePaths._();

  static const list = '/';
  static const word = '/word';
  static const feedback = '/feedback';
  static const config = '/config';
  static const session = '/session';
}

class HomeStackEntry {
  const HomeStackEntry(this.path, this.params);

  final String path;
  final Map<String, String> params;

  HomeStackEntry copyWith({
    String? path,
    Map<String, String>? params,
  }) {
    return HomeStackEntry(
      path ?? this.path,
      params ?? this.params,
    );
  }
}

class CoachStackEntry {
  const CoachStackEntry(this.path, this.params);

  final String path;
  final Map<String, String> params;
}

class AppRoutePath {
  const AppRoutePath({
    required this.tab,
    required this.homeStack,
    required this.studyStack,
    required this.coachStack,
    this.profileSection = ProfileSection.hub,
    this.examDetailId,
  });

  factory AppRoutePath.initial() {
    return const AppRoutePath(
      tab: AppTab.home,
      homeStack: [HomeStackEntry(HomeRoutePaths.home, {})],
      studyStack: [HomeStackEntry(HomeRoutePaths.levelList, {})],
      coachStack: [CoachStackEntry(CoachRoutePaths.list, {})],
    );
  }

  final AppTab tab;
  final List<HomeStackEntry> homeStack;
  final List<HomeStackEntry> studyStack;
  final List<CoachStackEntry> coachStack;
  final ProfileSection profileSection;
  final String? examDetailId;

  AppRoutePath copyWith({
    AppTab? tab,
    List<HomeStackEntry>? homeStack,
    List<HomeStackEntry>? studyStack,
    List<CoachStackEntry>? coachStack,
    ProfileSection? profileSection,
    String? examDetailId,
    bool clearExamDetail = false,
    bool clearCoachStack = false,
    bool resetHomeStack = false,
    bool resetStudyStack = false,
  }) {
    return AppRoutePath(
      tab: tab ?? this.tab,
      homeStack: resetHomeStack
          ? const [HomeStackEntry(HomeRoutePaths.home, {})]
          : homeStack ?? this.homeStack,
      studyStack: resetStudyStack
          ? const [HomeStackEntry(HomeRoutePaths.levelList, {})]
          : studyStack ?? this.studyStack,
      coachStack: clearCoachStack
          ? const [CoachStackEntry(CoachRoutePaths.list, {})]
          : coachStack ?? this.coachStack,
      profileSection: profileSection ?? this.profileSection,
      examDetailId:
          clearExamDetail ? null : examDetailId ?? this.examDetailId,
    );
  }
}
