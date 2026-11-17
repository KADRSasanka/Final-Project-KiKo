import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/day_key.dart';
import '../models/level_completion.dart';
import '../models/track_progress.dart';

class ProgressRepository {
  ProgressRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _child(String uid, String childId) =>
      _db.collection('users').doc(uid).collection('children').doc(childId);

  Stream<TrackProgress> watchTrack(String uid, String childId, String trackId) {
    return _child(uid, childId)
        .collection('progress')
        .doc(trackId)
        .snapshots()
        .map((snap) => TrackProgress.fromData(snap.data()));
  }

  /// Saves the best stars for a level, updates the daily streak, awards the
  /// daily bonus and any new badges. XP and coins for the level itself are
  /// only given the first time it is completed.
  Future<LevelCompletion> completeLevel({
    required String uid,
    required String childId,
    required String trackId,
    required String levelId,
    required int stars,
    required int xp,
    required int coins,
    required int trackLevelCount,
  }) {
    final childRef = _child(uid, childId);
    final progressRef = childRef.collection('progress').doc(trackId);
    final today = todayKey();
    final yesterday = yesterdayKey();

    return _db.runTransaction<LevelCompletion>((tx) async {
      // All reads first.
      final progressSnap = await tx.get(progressRef);
      final childSnap = await tx.get(childRef);
      final child = childSnap.data() ?? const <String, dynamic>{};

      final levels = <String, int>{
        for (final e in ((progressSnap.data()?['levels'] as Map?) ?? const {}).entries)
          e.key as String: (e.value as num).toInt(),
      };
      final previous = levels[levelId];
      final firstTime = previous == null;
      levels[levelId] = max(previous ?? 0, stars);

      // Streak: +1 if the last play day was yesterday, else restart at 1.
      final lastDay = child['lastPlayedDay'] as String?;
      var streak = (child['streak'] as num?)?.toInt() ?? 0;
      var dailyBonus = 0;
      if (lastDay != today) {
        streak = lastDay == yesterday ? streak + 1 : 1;
        dailyBonus = min(streak, 5);
      } else if (streak < 1) {
        streak = 1;
      }

      // Badges
      final xpTotal = ((child['xp'] as num?)?.toInt() ?? 0) + (firstTime ? xp : 0);
      final have = Set<String>.from((child['badges'] as List?) ?? const []);
      final earned = <String>[];
      void award(String id, bool condition) {
        if (condition && !have.contains(id)) earned.add(id);
      }

      award('first_level', true);
      award('three_stars', stars == 3);
      award('streak_3', streak >= 3);
      award('streak_7', streak >= 7);
      award('xp_100', xpTotal >= 100);
      award('track_$trackId', levels.length >= trackLevelCount);

      // Writes
      if (previous == null || stars > previous) {
        tx.set(
          progressRef,
          {
            'levels': {levelId: stars},
          },
          SetOptions(merge: true),
        );
      }

      final coinGain = (firstTime ? coins : 0) + dailyBonus;
      final update = <String, dynamic>{
        'streak': streak,
        'lastPlayedDay': today,
      };
      if (firstTime) update['xp'] = FieldValue.increment(xp);
      if (coinGain > 0) update['coins'] = FieldValue.increment(coinGain);
      if (earned.isNotEmpty) update['badges'] = FieldValue.arrayUnion(earned);
      tx.update(childRef, update);

      return LevelCompletion(
        firstTime: firstTime,
        newBadges: earned,
        streak: streak,
        dailyBonus: dailyBonus,
      );
    });
  }
}
