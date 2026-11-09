class SortingItem {
  const SortingItem({
    required this.label,
    required this.emoji,
    required this.binId,
    required this.hints,
  });

  final String label;
  final String emoji;
  final String binId;
  final List<String> hints;

  factory SortingItem.fromJson(Map<String, dynamic> json) {
    return SortingItem(
      label: json['label'] as String,
      emoji: json['emoji'] as String,
      binId: json['bin'] as String,
      hints: List<String>.from((json['hints'] as List?) ?? const []),
    );
  }
}

class SortingLevel {
  const SortingLevel({required this.binIds, required this.items});

  final List<String> binIds;
  final List<SortingItem> items;

  factory SortingLevel.fromJson(Map<String, dynamic> json) {
    return SortingLevel(
      binIds: List<String>.from(json['bins'] as List),
      items: [
        for (final i in json['items'] as List)
          SortingItem.fromJson(i as Map<String, dynamic>),
      ],
    );
  }
}
