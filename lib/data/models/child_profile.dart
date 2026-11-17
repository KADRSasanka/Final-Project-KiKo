import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/day_key.dart';

/// Stored at: users/{parentUid}/children/{childId}
class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.nickname,
    required this.avatarId,
    required this.age,
    this.xp = 0,
    this.coins = 0,
    this.streak = 0,
    this.lastPlayedDay,
    this.badges = const [],
    this.ownedItems = const [],
    this.equipped = const {},
    this.dailyLimitMinutes = 0,
    this.playSeconds = const {},
    this.createdAt,
  });

  final String id;
  final String nickname;
  final String avatarId;
  final int age;
  final int xp;
  final int coins;
  final int streak;
  final String? lastPlayedDay; // "yyyy-MM-dd"
  final List<String> badges;
  final List<String> ownedItems;
  final Map<String, String> equipped; // slot -> item id
  final int dailyLimitMinutes; // 0 = no limit
  final Map<String, int> playSeconds; // "yyyyMMdd" -> seconds played
  final DateTime? createdAt;

  String? get hatId => equipped['hat'];
  String? get backgroundId => equipped['background'];

  /// The streak is only alive if the child played today or yesterday.
  int get currentStreak {
    if (lastPlayedDay == todayKey() || lastPlayedDay == yesterdayKey()) {
      return streak;
    }
    return 0;
  }

  bool get playedToday => lastPlayedDay == todayKey();

  // ---- play time ----
  int secondsOn(DateTime day) => playSeconds[dayKeyCompact(day)] ?? 0;

  int get playedTodaySeconds => playSeconds[todayCompact()] ?? 0;

  bool get hasLimit => dailyLimitMinutes > 0;

  bool get isTimeUp => hasLimit && playedTodaySeconds >= dailyLimitMinutes * 60;

  factory ChildProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final rawEquipped = (data['equipped'] as Map?) ?? const {};
    final rawPlay = (data['playSeconds'] as Map?) ?? const {};
    return ChildProfile(
      id: doc.id,
      nickname: data['nickname'] as String? ?? 'Player',
      avatarId: data['avatarId'] as String? ?? 'fox',
      age: (data['age'] as num?)?.toInt() ?? 8,
      xp: (data['xp'] as num?)?.toInt() ?? 0,
      coins: (data['coins'] as num?)?.toInt() ?? 0,
      streak: (data['streak'] as num?)?.toInt() ?? 0,
      lastPlayedDay: data['lastPlayedDay'] as String?,
      badges: List<String>.from((data['badges'] as List?) ?? const []),
      ownedItems: List<String>.from((data['ownedItems'] as List?) ?? const []),
      equipped: {
        for (final e in rawEquipped.entries) e.key as String: e.value as String,
      },
      dailyLimitMinutes: (data['dailyLimitMinutes'] as num?)?.toInt() ?? 0,
      playSeconds: {
        for (final e in rawPlay.entries)
          e.key as String: (e.value as num).toInt(),
      },
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
