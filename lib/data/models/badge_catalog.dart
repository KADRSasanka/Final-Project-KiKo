class BadgeInfo {
  const BadgeInfo(this.id, this.emoji, this.title, this.description);

  final String id;
  final String emoji;
  final String title;
  final String description; // "how to earn"
}

/// All badges. Awarding rules live in ProgressRepository / ShopRepository.
class BadgeCatalog {
  BadgeCatalog._();

  static const all = <BadgeInfo>[
    BadgeInfo('first_level', '🌟', 'First Steps', 'Finish your very first level.'),
    BadgeInfo('three_stars', '🏅', 'Perfect Score', 'Get 3 stars on a level.'),
    BadgeInfo('streak_3', '🔥', 'On Fire', 'Play 3 days in a row.'),
    BadgeInfo('streak_7', '⚡', 'Week Warrior', 'Play 7 days in a row.'),
    BadgeInfo('xp_100', '💎', 'XP Hunter', 'Earn 100 XP.'),
    BadgeInfo('first_purchase', '🛍️', 'Shopper', 'Buy something in the shop.'),
    BadgeInfo('track_math', '➕', 'Math Master', 'Finish every Math level.'),
    BadgeInfo('track_science', '🔬', 'Science Star', 'Finish every Science level.'),
    BadgeInfo('track_language', '📚', 'Word Wizard', 'Finish every Language level.'),
    BadgeInfo('track_geography', '🧭', 'World Explorer', 'Finish every Geography level.'),
    BadgeInfo('track_eco', '🌱', 'Eco Hero', 'Finish every Eco level.'),
  ];

  static BadgeInfo? byId(String id) {
    for (final b in all) {
      if (b.id == id) return b;
    }
    return null;
  }
}
