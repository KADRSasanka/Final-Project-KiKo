/// Calendar day as "yyyy-MM-dd" (device local time). Used for streaks.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String todayKey() => dayKey(DateTime.now());

String yesterdayKey() {
  final now = DateTime.now();
  return dayKey(DateTime(now.year, now.month, now.day - 1));
}

/// "yyyyMMdd": used as Firestore map keys for play time (no hyphens).
String dayKeyCompact(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}'
    '${d.month.toString().padLeft(2, '0')}'
    '${d.day.toString().padLeft(2, '0')}';

String todayCompact() => dayKeyCompact(DateTime.now());
