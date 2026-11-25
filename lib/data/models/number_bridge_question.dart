class NumberBridgeQuestion {
  const NumberBridgeQuestion({
    required this.tokens,
    required this.answer,
    required this.options,
    required this.hints,
  });

  /// The equation as planks, with "?" marking the missing one,
  /// e.g. ["7", "+", "?", "=", "12"].
  final List<String> tokens;
  final int answer;
  final List<int> options; // number tiles to choose from (includes the answer)
  final List<String> hints;

  factory NumberBridgeQuestion.fromJson(Map<String, dynamic> json) {
    return NumberBridgeQuestion(
      tokens: List<String>.from(json['tokens'] as List),
      answer: (json['answer'] as num).toInt(),
      options: [for (final o in json['options'] as List) (o as num).toInt()],
      hints: List<String>.from((json['hints'] as List?) ?? const []),
    );
  }
}
