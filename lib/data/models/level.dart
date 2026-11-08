class Level {
  const Level({
    required this.id,
    required this.trackId,
    required this.index,
    required this.title,
    required this.activity,
    required this.minutes,
    required this.xp,
  });

  final String id;
  final String trackId;
  final int index; // 0-based position in the track
  final String title;
  final String activity; // e.g. 'quiz', 'sorting'
  final int minutes;
  final int xp;

  int get number => index + 1;
  int get coins => xp ~/ 2;

  factory Level.fromJson(String trackId, int index, Map<String, dynamic> json) {
    return Level(
      id: json['id'] as String,
      trackId: trackId,
      index: index,
      title: json['title'] as String,
      activity: json['activity'] as String,
      minutes: (json['minutes'] as num?)?.toInt() ?? 2,
      xp: (json['xp'] as num?)?.toInt() ?? 10,
    );
  }
}
