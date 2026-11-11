import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/fraction_question.dart';
import '../models/level.dart';
import '../models/matching_level.dart';
import '../models/quiz_question.dart';
import '../models/sorting_level.dart';

/// Loads content from assets/content/
class ContentRepository {
  Future<Map<String, dynamic>> _json(String file) async {
    final raw = await rootBundle.loadString('assets/content/$file');
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Level list: assets/content/{trackId}.json
  Future<List<Level>> loadLevels(String trackId) async {
    final data = await _json('$trackId.json');
    final list = data['levels'] as List;
    return [
      for (var i = 0; i < list.length; i++)
        Level.fromJson(trackId, i, list[i] as Map<String, dynamic>),
    ];
  }

  /// Quiz questions: assets/content/questions_{levelId}.json
  Future<List<QuizQuestion>> loadQuestions(String levelId) async {
    final data = await _json('questions_$levelId.json');
    return [
      for (final q in data['questions'] as List)
        QuizQuestion.fromJson(q as Map<String, dynamic>),
    ];
  }

  /// Sorting game: assets/content/sorting_{levelId}.json
  Future<SortingLevel> loadSortingLevel(String levelId) async =>
      SortingLevel.fromJson(await _json('sorting_$levelId.json'));

  /// Fraction pizza: assets/content/fractions_{levelId}.json
  Future<List<FractionQuestion>> loadFractionQuestions(String levelId) async {
    final data = await _json('fractions_$levelId.json');
    return [
      for (final q in data['questions'] as List)
        FractionQuestion.fromJson(q as Map<String, dynamic>),
    ];
  }

  /// Matching game: assets/content/matching_{levelId}.json
  Future<MatchingLevel> loadMatchingLevel(String levelId) async =>
      MatchingLevel.fromJson(await _json('matching_$levelId.json'));
}
