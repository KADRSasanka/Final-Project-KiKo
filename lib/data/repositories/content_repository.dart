import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/level.dart';
import '../models/quiz_question.dart';

/// Loads content from assets/content/
class ContentRepository {
  /// Level list: assets/content/{trackId}.json
  Future<List<Level>> loadLevels(String trackId) async {
    final raw = await rootBundle.loadString('assets/content/$trackId.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final list = data['levels'] as List;
    return [
      for (var i = 0; i < list.length; i++)
        Level.fromJson(trackId, i, list[i] as Map<String, dynamic>),
    ];
  }

  /// Quiz questions: assets/content/questions_{levelId}.json
  Future<List<QuizQuestion>> loadQuestions(String levelId) async {
    final raw =
        await rootBundle.loadString('assets/content/questions_$levelId.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return [
      for (final q in data['questions'] as List)
        QuizQuestion.fromJson(q as Map<String, dynamic>),
    ];
  }
}
