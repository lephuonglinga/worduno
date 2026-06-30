import 'package:flutter/foundation.dart';

import '../../../../app/di/injection.dart';
import '../../application/services/i_coach_service.dart';
import '../../domain/entities/coach_entities.dart';

enum CoachSessionPhase {
  loading,
  explainLoading,
  explain,
  explainError,
  writing,
  evaluating,
  feedback,
  completed,
}

class CoachSessionViewModel extends ChangeNotifier {
  CoachSessionViewModel({
    ICoachService? coachService,
  }) : _coachService = coachService ?? getIt<ICoachService>();

  final ICoachService _coachService;

  bool _isDisposed = false;
  CoachSessionPhase phase = CoachSessionPhase.loading;
  String? errorMessage;

  CoachSession? session;
  int currentIndex = 0;
  CoachExplainResult? explainResult;
  CoachEvaluateResult? evaluateResult;
  String userSentence = '';
  bool skippedExplain = false;

  CoachWord? get currentWord {
    final words = session?.words;
    if (words == null || currentIndex >= words.length) return null;
    return words[currentIndex];
  }

  int get totalWords => session?.words.length ?? 0;
  bool get hasSession => session != null && totalWords > 0;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> initSession() async {
    phase = CoachSessionPhase.loading;
    errorMessage = null;
    notifyListeners();

    session = _coachService.currentSession;
    if (!hasSession) {
      errorMessage = 'No coach session found. Please configure again.';
      notifyListeners();
      return;
    }

    currentIndex = 0;
    userSentence = '';
    evaluateResult = null;
    skippedExplain = false;
    await _loadExplain();
  }

  Future<void> _loadExplain() async {
    final word = currentWord;
    if (word == null) return;

    phase = CoachSessionPhase.explainLoading;
    errorMessage = null;
    notifyListeners();

    try {
      explainResult = await _coachService.getExplanation(word);
      skippedExplain = false;
      phase = CoachSessionPhase.explain;
    } catch (error) {
      errorMessage = error.toString();
      phase = CoachSessionPhase.explainError;
    }
    notifyListeners();
  }

  void retryExplain() {
    _loadExplain();
  }

  void skipExplain() {
    skippedExplain = true;
    explainResult = null;
    phase = CoachSessionPhase.writing;
    notifyListeners();
  }

  void acknowledgeExplain() {
    phase = CoachSessionPhase.writing;
    notifyListeners();
  }

  void updateSentence(String value) {
    userSentence = value;
    notifyListeners();
  }

  Future<void> submitSentence() async {
    final word = currentWord;
    if (word == null) return;

    final sentence = userSentence.trim();
    if (sentence.isEmpty) {
      errorMessage = 'Please write a sentence before submitting.';
      notifyListeners();
      return;
    }

    phase = CoachSessionPhase.evaluating;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _coachService.evaluateSentence(
        word: word,
        sentence: sentence,
      );
      evaluateResult = result;
      await _coachService.saveCoachHistory(
        word: word,
        userSentence: sentence,
        result: result,
      );
      phase = CoachSessionPhase.feedback;
    } catch (error) {
      errorMessage = error.toString();
      phase = CoachSessionPhase.writing;
    }
    notifyListeners();
  }

  Future<void> nextWord() async {
    if (currentIndex + 1 >= totalWords) {
      phase = CoachSessionPhase.completed;
      _coachService.clearSession();
      notifyListeners();
      return;
    }

    currentIndex++;
    userSentence = '';
    evaluateResult = null;
    skippedExplain = false;
    await _loadExplain();
  }

  void endSession() {
    _coachService.clearSession();
  }
}
