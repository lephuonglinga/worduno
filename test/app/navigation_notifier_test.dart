import 'package:flutter_test/flutter_test.dart';
import 'package:worduno/app/navigation/app_navigation_notifier.dart';
import 'package:worduno/app/routes/route_paths.dart';

void main() {
  group('AppNavigationNotifier', () {
    late AppNavigationNotifier notifier;

    setUp(() {
      notifier = AppNavigationNotifier();
    });

    test('starts on home tab at home gateway', () {
      expect(notifier.configuration.tab, AppTab.home);
      expect(notifier.configuration.homeStack.last.path, HomeRoutePaths.home);
      expect(
        notifier.configuration.studyStack.last.path,
        HomeRoutePaths.levelList,
      );
    });

    test('selectTab switches bottom navigation', () {
      notifier.selectTab(AppTab.dashboard);
      expect(notifier.configuration.tab, AppTab.dashboard);
    });

    test('openStudyRoute pushes onto study stack', () {
      notifier.openStudyRoute(
        HomeRoutePaths.unitList,
        params: {'level': 'b1'},
      );
      expect(notifier.configuration.tab, AppTab.study);
      expect(notifier.configuration.studyStack.length, 2);
      expect(
        notifier.configuration.studyStack.last.path,
        HomeRoutePaths.unitList,
      );
    });

    test('openHomeRoute pushes onto home stack', () {
      notifier.openHomeRoute(HomeRoutePaths.examConfig);
      expect(notifier.configuration.tab, AppTab.home);
      expect(notifier.configuration.homeStack.length, 2);
      expect(
        notifier.configuration.homeStack.last.path,
        HomeRoutePaths.examConfig,
      );
    });

    test('popStudyRoute removes last entry', () {
      notifier.openStudyRoute(HomeRoutePaths.unitList, params: {'level': 'b1'});
      expect(notifier.popStudyRoute(), isTrue);
      expect(notifier.configuration.studyStack.length, 1);
    });

    test('popHomeRoute returns false at root', () {
      expect(notifier.popHomeRoute(), isFalse);
    });

    test('openExamDetail switches to profile exam history', () {
      notifier.openExamDetail('exam_1');
      expect(notifier.configuration.tab, AppTab.profile);
      expect(
        notifier.configuration.profileSection,
        ProfileSection.examHistory,
      );
      expect(notifier.configuration.examDetailId, 'exam_1');
    });

    test('popExamDetail clears detail id', () {
      notifier.openExamDetail('exam_1');
      expect(notifier.popExamDetail(), isTrue);
      expect(notifier.configuration.examDetailId, isNull);
    });

    test('resetHomeToRoot clears nested home stack', () {
      notifier.openHomeRoute(HomeRoutePaths.examConfig);
      notifier.resetHomeToRoot();
      expect(notifier.configuration.homeStack.length, 1);
      expect(notifier.configuration.homeStack.last.path, HomeRoutePaths.home);
    });
  });
}
