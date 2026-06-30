import 'dart:convert';
import 'dart:math';

import '../../../../shared/vocabulary/application/services/i_vocabulary_service.dart';
import '../../../../shared/word_state/application/services/word_state_store.dart';
import '../../domain/entities/coach_entities.dart';
import '../../domain/entities/coach_star_filter.dart';
import '../../domain/repositories/i_coach_repository.dart';
import '../datasources/i_coach_ai_data_source.dart';
import '../datasources/i_coach_history_local_data_source.dart';

class CoachRepositoryImpl implements ICoachRepository {
  CoachRepositoryImpl(
    this._vocabularyService,
    this._wordStateStore,
    this._aiDataSource,
    this._historyDataSource,
  );

  final IVocabularyService _vocabularyService;
  final WordStateStore _wordStateStore;
  final ICoachAiDataSource _aiDataSource;
  final ICoachHistoryLocalDataSource _historyDataSource;

  final _random = Random();

  @override
  Future<int> countAvailableWords(CoachSessionConfig config) async {
    final pool = await _buildWordPool(config);
    return pool.length;
  }

  @override
  Future<CoachSession> buildSession(CoachSessionConfig config) async {
    final pool = await _buildWordPool(config);
    if (pool.isEmpty) {
      throw StateError('No words match the selected filters.');
    }

    final count = config.wordCount.clamp(1, pool.length);
    final shuffled = List<CoachWord>.from(pool)..shuffle(_random);
    return CoachSession(
      words: shuffled.take(count).toList(growable: false),
      config: config,
    );
  }

  @override
  Future<CoachExplainResult> getExplanation(CoachWord word) async {
    await _wordStateStore.ensureLoaded(word.unitId, forceReload: true);
    final state = _wordStateStore.stateFor(
      unitId: word.unitId,
      termId: word.term.id,
    );

    if (state.explanation != null && state.explanation!.isNotEmpty) {
      final decoded = jsonDecode(state.explanation!) as Map<String, dynamic>;
      return CoachExplainResult.fromJson(decoded);
    }

    final response = await _aiDataSource.explainWord(
      word: word.term.text,
      definition: word.term.definition,
    );
    final result = CoachExplainResult.fromJson(response);
    final json = jsonEncode(result.toJson());

    await _wordStateStore.saveExplanation(
      unitId: word.unitId,
      termId: word.term.id,
      explanationJson: json,
    );

    return result;
  }

  @override
  Future<CoachEvaluateResult> evaluateSentence({
    required CoachWord word,
    required String sentence,
  }) async {
    final response = await _aiDataSource.evaluateSentence(
      word: word.term.text,
      sentence: sentence,
    );
    return CoachEvaluateResult.fromJson(response);
  }

  @override
  Future<void> saveCoachHistory({
    required CoachWord word,
    required String userSentence,
    required CoachEvaluateResult result,
  }) async {
    await _wordStateStore.ensurePersisted(
      unitId: word.unitId,
      termId: word.term.id,
    );

    final entry = CoachHistoryEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}-${word.term.id}',
      date: DateTime.now(),
      unitId: word.unitId,
      termId: word.term.id,
      userSentence: userSentence,
      responseJson: jsonEncode(result.rawJson),
    );
    await _historyDataSource.insert(entry);
  }

  Future<List<CoachWord>> _buildWordPool(CoachSessionConfig config) async {
    final targets = await _resolveUnitTargets(config);
    final words = <CoachWord>[];

    for (final target in targets) {
      await _wordStateStore.ensureLoaded(target.unitId, forceReload: true);
      final terms = await _vocabularyService.getTerms(
        levelCode: target.levelCode,
        unitName: target.unitName,
      );

      for (final term in terms) {
        final state = _wordStateStore.stateFor(
          unitId: target.unitId,
          termId: term.id,
        );
        if (!_matchesStarFilter(state.isStarred, config.starFilter)) {
          continue;
        }
        words.add(
          CoachWord(
            levelCode: target.levelCode,
            unitName: target.unitName,
            unitId: target.unitId,
            term: term,
          ),
        );
      }
    }

    return words;
  }

  bool _matchesStarFilter(bool isStarred, CoachStarFilter filter) {
    return switch (filter) {
      CoachStarFilter.all => true,
      CoachStarFilter.starred => isStarred,
      CoachStarFilter.notStarred => !isStarred,
    };
  }

  Future<List<_UnitTarget>> _resolveUnitTargets(CoachSessionConfig config) async {
    if (config.isUnitScoped) {
      final unitId = config.fixedUnitId?.isNotEmpty == true
          ? config.fixedUnitId!
          : await _resolveUnitId(
              levelCode: config.fixedLevelCode!,
              unitName: config.fixedUnitName!,
            );
      return [
        _UnitTarget(
          levelCode: config.fixedLevelCode!,
          unitName: config.fixedUnitName!,
          unitId: unitId,
        ),
      ];
    }

    final levels = config.levelCodes.isEmpty
        ? (await _vocabularyService.getLevels()).map((l) => l.code).toList()
        : config.levelCodes;

    final targets = <_UnitTarget>[];
    for (final levelCode in levels) {
      final units = await _vocabularyService.getUnits(levelCode);
      for (final unit in units) {
        final key = unitKey(levelCode, unit.name);
        if (config.unitKeys.isNotEmpty && !config.unitKeys.contains(key)) {
          continue;
        }
        targets.add(
          _UnitTarget(
            levelCode: levelCode,
            unitName: unit.name,
            unitId: unit.id,
          ),
        );
      }
    }
    return targets;
  }

  Future<String> _resolveUnitId({
    required String levelCode,
    required String unitName,
  }) async {
    final units = await _vocabularyService.getUnits(levelCode);
    final index = units.indexWhere((unit) => unit.name == unitName);
    return index == -1 ? '' : units[index].id;
  }

  static String unitKey(String levelCode, String unitName) =>
      '$levelCode|$unitName';

  static String unitLabel({
    required String levelCode,
    required String unitName,
    required bool showLevelPrefix,
  }) {
    return showLevelPrefix ? '$levelCode • $unitName' : unitName;
  }
}

class _UnitTarget {
  const _UnitTarget({
    required this.levelCode,
    required this.unitName,
    required this.unitId,
  });

  final String levelCode;
  final String unitName;
  final String unitId;
}
