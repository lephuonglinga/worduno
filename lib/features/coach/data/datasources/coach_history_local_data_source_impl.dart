import '../../../../core/database/app_database.dart';
import '../../domain/entities/coach_entities.dart';
import 'i_coach_history_local_data_source.dart';

class CoachHistoryLocalDataSourceImpl implements ICoachHistoryLocalDataSource {
  CoachHistoryLocalDataSourceImpl(this._database);

  final AppDatabase _database;

  @override
  Future<void> insert(CoachHistoryEntry entry) async {
    final db = await _database.database;
    await db.insert('coach_history', {
      'id': entry.id,
      'date': entry.date.toIso8601String(),
      'unit_id': entry.unitId,
      'term_id': entry.termId,
      'user_sentence': entry.userSentence,
      'response_json': entry.responseJson,
    });
  }
}
