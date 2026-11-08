import 'dart:ui';

/// Starter avatars (emoji for now; swap for artwork in assets/avatars later).
class AvatarOption {
  const AvatarOption(this.id, this.emoji, this.color);

  final String id;
  final String emoji;
  final Color color;
}

class AvatarCatalog {
  AvatarCatalog._();

  static const all = <AvatarOption>[
    AvatarOption('fox', '🦊', Color(0xFFFFD6A5)),
    AvatarOption('panda', '🐼', Color(0xFFD9E4FF)),
    AvatarOption('cat', '🐱', Color(0xFFFFC9C9)),
    AvatarOption('dino', '🦖', Color(0xFFC8F2DA)),
    AvatarOption('owl', '🦉', Color(0xFFE0D9FF)),
    AvatarOption('frog', '🐸', Color(0xFFD2F5B8)),
    AvatarOption('lion', '🦁', Color(0xFFFFEBA6)),
    AvatarOption('robot', '🤖', Color(0xFFCFEFFF)),
  ];

  static AvatarOption byId(String id) =>
      all.firstWhere((a) => a.id == id, orElse: () => all.first);
}
