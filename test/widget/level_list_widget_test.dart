import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:worduno/app/navigation/app_navigation_notifier.dart';
import 'package:worduno/features/home/presentation/viewmodels/level_list_view_model.dart';
import 'package:worduno/features/home/presentation/views/level_list_page.dart';

import '../helpers/fakes.dart';
import '../helpers/test_database.dart';

void main() {
  initTestDatabase();

  group('LevelListPage widget tests', () {
    testWidgets('study root shows Học tập and no Create Exam', (tester) async {
      final nav = AppNavigationNotifier();
      final temp = createTempDbPath();
      final db = openTestDatabase(temp.dbPath);
      final store = wordStateStoreFor(db);
      final viewModel = LevelListViewModel(
        vocabularyService: FakeVocabularyService(),
        wordStateStore: store,
        database: db,
      );

      addTearDown(() async {
        viewModel.dispose();
        await db.close();
        deleteTempDir(temp.tempDir);
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppNavigationNotifier>.value(value: nav),
            ChangeNotifierProvider<LevelListViewModel>.value(value: viewModel),
          ],
          child: const MaterialApp(home: LevelListPage()),
        ),
      );
      await tester.pump();

      expect(find.text('Học tập'), findsOneWidget);
      expect(find.text('Create Exam'), findsNothing);
      expect(find.text('Tìm level...'), findsOneWidget);
    });
  });
}
