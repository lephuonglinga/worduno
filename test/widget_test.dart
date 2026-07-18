import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worduno/app/app.dart';
import 'package:worduno/app/di/injection.dart';
import 'package:worduno/core/constants/app_constants.dart';
import 'package:worduno/features/dashboard/application/services/i_dashboard_service.dart';
import 'package:worduno/shared/vocabulary/application/services/i_vocabulary_service.dart';

import 'helpers/fakes.dart';
import 'helpers/test_app_setup.dart';

void main() {
  setUpAll(() async {
    await setupWordunoTestDependencies();
    await getIt.unregister<IVocabularyService>();
    await getIt.unregister<IDashboardService>();
    getIt.registerLazySingleton<IVocabularyService>(
      () => FakeVocabularyService(),
    );
    getIt.registerLazySingleton<IDashboardService>(FakeDashboardService.new);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppConstants.hasSeenOnboardingKey: true,
    });
  });

  testWidgets('app launches with bottom navigation', (tester) async {
    await tester.pumpWidget(const WordunoApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Học tập'), findsOneWidget);
    expect(find.text('Thống kê'), findsOneWidget);
    expect(find.text('Hồ sơ'), findsOneWidget);
  });

  testWidgets('bottom navigation switches tabs', (tester) async {
    await tester.pumpWidget(const WordunoApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Thống kê'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Thống kê'), findsWidgets);
  });
}
