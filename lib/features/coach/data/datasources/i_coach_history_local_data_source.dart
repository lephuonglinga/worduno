import '../../domain/entities/coach_entities.dart';

abstract class ICoachHistoryLocalDataSource {
  Future<void> insert(CoachHistoryEntry entry);
}
