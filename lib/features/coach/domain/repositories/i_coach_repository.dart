import '../../domain/entities/coach_entities.dart';

abstract class ICoachRepository {
  Future<int> countAvailableWords(CoachSessionConfig config);

  Future<CoachSession> buildSession(CoachSessionConfig config);

  Future<CoachExplainResult> getExplanation(CoachWord word);

  Future<CoachEvaluateResult> evaluateSentence({
    required CoachWord word,
    required String sentence,
  });

  Future<void> saveCoachHistory({
    required CoachWord word,
    required String userSentence,
    required CoachEvaluateResult result,
  });
}
