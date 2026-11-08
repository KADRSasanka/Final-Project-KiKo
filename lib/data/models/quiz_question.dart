class QuizQuestion {
  const QuizQuestion({
    required this.prompt,
    required this.options,
    required this.answer,
    required this.hints,
  });

  final String prompt;
  final List<String> options;
  final int answer; // index of the correct option
  final List<String> hints; // from gentle to strong

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      prompt: json['prompt'] as String,
      options: List<String>.from(json['options'] as List),
      answer: (json['answer'] as num).toInt(),
      hints: List<String>.from((json['hints'] as List?) ?? const []),
    );
  }
}
