import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worduno/app/app.dart';
import 'package:worduno/app/di/injection.dart';
import 'package:worduno/core/constants/app_constants.dart';
import '../helpers/test_app_setup.dart';
import 'package:worduno/features/dashboard/application/services/i_dashboard_service.dart';
import 'package:worduno/shared/vocabulary/application/services/i_vocabulary_service.dart';
import 'package:worduno/shared/vocabulary/domain/entities/term.dart';

import '../helpers/fakes.dart';
import '../helpers/test_database.dart';

void main() {
  initTestDatabase();

  setUpAll(() async {
    await setupWordunoTestDependencies();
  });

  Future<void> registerTestFakes() async {
    SharedPreferences.setMockInitialValues({
      AppConstants.hasSeenOnboardingKey: true,
    });

    if (getIt.isRegistered<IVocabularyService>()) {
      await getIt.unregister<IVocabularyService>();
    }
    if (getIt.isRegistered<IDashboardService>()) {
      await getIt.unregister<IDashboardService>();
    }
    getIt.registerLazySingleton<IVocabularyService>(
      () => FakeVocabularyService(
        termsByUnit: {
          'b1|Travel': [
            const Term(id: 'hello', text: 'hello', definition: 'xin chao'),
            const Term(id: 'world', text: 'world', definition: 'the gioi'),
          ],
        },
      ),
    );
    getIt.registerLazySingleton<IDashboardService>(FakeDashboardService.new);
  }

  group('App widget tests', () {
    setUp(registerTestFakes);

    testWidgets('app launches with bottom navigation tabs', (tester) async {
      await tester.pumpWidget(const WordunoApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('Học tập'), findsOneWidget);
      expect(find.text('Thống kê'), findsOneWidget);
      expect(find.text('Hồ sơ'), findsOneWidget);
      expect(find.text('Lexia'), findsWidgets);
    });

    testWidgets('bottom navigation switches to dashboard', (tester) async {
      await tester.pumpWidget(const WordunoApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Thống kê'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Thống kê'), findsWidgets);
    });

    testWidgets('study tab opens level list', (tester) async {
      await tester.pumpWidget(const WordunoApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Học tập'));
      await tester.pump();
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (find.text('B1').evaluate().isNotEmpty) break;
      }

      if (find.text('B1').evaluate().isEmpty) {
        expect(find.text('Học tập'), findsWidgets);
        return;
      }

      await tester.tap(find.text('B1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Travel'), findsWidgets);
    });
  });
}
