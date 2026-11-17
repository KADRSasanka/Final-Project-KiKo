/// What happened when a level was finished (shown on the result screen).
class LevelCompletion {
  const LevelCompletion({
    required this.firstTime,
    required this.newBadges,
    required this.streak,
    required this.dailyBonus,
  });

  final bool firstTime; // XP and coins are only awarded the first time
  final List<String> newBadges; // badge ids
  final int streak; // days in a row, including today
  final int dailyBonus; // bonus coins for the first level of a new day
}
