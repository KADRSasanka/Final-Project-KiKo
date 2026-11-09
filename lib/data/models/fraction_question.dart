class FractionQuestion {
  const FractionQuestion({
    required this.denominator,
    required this.numerator,
    required this.label,
    required this.hints,
  });

  final int denominator;
  final int numerator;
  final String label; // e.g. "3/4"
  final List<String> hints;

  factory FractionQuestion.fromJson(Map<String, dynamic> json) {
    return FractionQuestion(
      denominator: (json['denominator'] as num).toInt(),
      numerator: (json['numerator'] as num).toInt(),
      label: json['label'] as String,
      hints: List<String>.from((json['hints'] as List?) ?? const []),
    );
  }
}
