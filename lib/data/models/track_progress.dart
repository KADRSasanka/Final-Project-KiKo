import 'level.dart';

/// Stars (1-3) per completed level in one track.
/// Stored at: users/{uid}/children/{childId}/progress/{trackId}
class TrackProgress {
  const TrackProgress([this.stars = const {}]);

  final Map<String, int> stars;

  factory TrackProgress.fromData(Map<String, dynamic>? data) {
    final raw = (data?['levels'] as Map?) ?? const {};
    return TrackProgress({
      for (final e in raw.entries) e.key as String: (e.value as num).toInt(),
    });
  }

  bool isDone(String levelId) => stars.containsKey(levelId);

  int starsFor(String levelId) => stars[levelId] ?? 0;

  /// A level opens when the one before it is done.
  bool isUnlocked(List<Level> levels, int index) =>
      index == 0 || isDone(levels[index - 1].id);

  int doneIn(List<Level> levels) => levels.where((l) => isDone(l.id)).length;
}
