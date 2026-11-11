class MatchPair {
  const MatchPair({
    required this.id,
    required this.itemEmoji,
    required this.itemLabel,
    required this.targetEmoji,
    required this.targetLabel,
    required this.hints,
  });

  final int id; // position in the JSON list; pairs match one-to-one by id
  final String itemEmoji;
  final String itemLabel; // may be empty (e.g. flags)
  final String targetEmoji; // may be empty
  final String targetLabel;
  final List<String> hints;

  factory MatchPair.fromJson(int id, Map<String, dynamic> json) {
    final item = json['item'] as Map<String, dynamic>;
    final target = json['target'] as Map<String, dynamic>;
    return MatchPair(
      id: id,
      itemEmoji: item['emoji'] as String? ?? '',
      itemLabel: item['label'] as String? ?? '',
      targetEmoji: target['emoji'] as String? ?? '',
      targetLabel: target['label'] as String? ?? '',
      hints: List<String>.from((json['hints'] as List?) ?? const []),
    );
  }
}

class MatchingLevel {
  const MatchingLevel({required this.prompt, required this.pairs});

  final String prompt;
  final List<MatchPair> pairs;

  factory MatchingLevel.fromJson(Map<String, dynamic> json) {
    final list = json['pairs'] as List;
    return MatchingLevel(
      prompt: json['prompt'] as String? ?? 'Match each one!',
      pairs: [
        for (var i = 0; i < list.length; i++)
          MatchPair.fromJson(i, list[i] as Map<String, dynamic>),
      ],
    );
  }
}
