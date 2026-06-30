import '../../domain/entities/coach_entities.dart';
import '../../domain/repositories/i_coach_repository.dart';
import 'i_coach_service.dart';

class CoachServiceImpl implements ICoachService {
  CoachServiceImpl(this._repository);

  final ICoachRepository _repository;

  CoachSession? _currentSession;

  @override
  CoachSession? get currentSession => _currentSession;

  @override
  Future<int> countAvailableWords(CoachSessionConfig config) =>
      _repository.countAvailableWords(config);

  @override
  Future<void> startSession(CoachSessionConfig config) async {
    _currentSession = await _repository.buildSession(config);
  }

  @override
  void clearSession() {
    _currentSession = null;
  }

  @override
  Future<CoachExplainResult> getExplanation(CoachWord word) =>
      _repository.getExplanation(word);

  @override
  Future<CoachEvaluateResult> evaluateSentence({
    required CoachWord word,
    required String sentence,
  }) =>
      _repository.evaluateSentence(word: word, sentence: sentence);

  @override
  Future<void> saveCoachHistory({
    required CoachWord word,
    required String userSentence,
    required CoachEvaluateResult result,
  }) =>
      _repository.saveCoachHistory(
        word: word,
        userSentence: userSentence,
        result: result,
      );
}
