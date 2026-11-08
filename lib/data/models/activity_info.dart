class ActivityInfo {
  const ActivityInfo(this.label, this.emoji);

  final String label;
  final String emoji;

  static const _fallback = ActivityInfo('Challenge', '⭐');

  static const _all = <String, ActivityInfo>{
    'quiz': ActivityInfo('Quick Quiz', '🧠'),
    'boss_battle': ActivityInfo('Boss Battle', '⚔️'),
    'fraction_pizza': ActivityInfo('Fraction Pizza', '🍕'),
    'number_bridge': ActivityInfo('Number Bridge', '🌉'),
    'solar_system': ActivityInfo('Planet Parade', '🪐'),
    'matching': ActivityInfo('Match-Up', '🧩'),
    'body_explorer': ActivityInfo('Body Explorer', '🫀'),
    'virtual_lab': ActivityInfo('Virtual Lab', '🧪'),
    'spelling_tiles': ActivityInfo('Spelling Tiles', '🔤'),
    'word_hunt': ActivityInfo('Word Hunt', '🔎'),
    'grammar_fixer': ActivityInfo('Sentence Fixer', '✏️'),
    'story_builder': ActivityInfo('Story Builder', '📖'),
    'map_pins': ActivityInfo('Map Pins', '📍'),
    'flag_match': ActivityInfo('Flag Match', '🚩'),
    'landmark_quest': ActivityInfo('Landmark Quest', '🗼'),
    'sorting': ActivityInfo('Sorting Game', '♻️'),
    'cleanup': ActivityInfo('Clean-up', '🧹'),
    'eco_mission': ActivityInfo('Eco Mission', '🌱'),
  };

  static ActivityInfo of(String activity) => _all[activity] ?? _fallback;
}
