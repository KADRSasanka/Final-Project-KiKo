class SpellingWord {
  const SpellingWord({
    required this.word,
    required this.emoji,
    required this.clue,
    required this.hints,
  });

  final String word; // UPPERCASE
  final String emoji;
  final String clue;
  final List<String> hints;

  factory SpellingWord.fromJson(Map<String, dynamic> json) {
    return SpellingWord(
      word: (json['word'] as String).toUpperCase(),
      emoji: json['emoji'] as String? ?? '',
      clue: json['clue'] as String? ?? '',
      hints: List<String>.from((json['hints'] as List?) ?? const []),
    );
  }
}
