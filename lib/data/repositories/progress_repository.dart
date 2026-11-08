import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// Saves the best stars for a level. XP and coins are awarded only the
  /// first time a level is completed. Returns true if it was the first time.
  Future<bool> completeLevel({
    required String uid,
    required String childId,
    required String trackId,
    required String levelId,
    required int stars,
    required int xp,
    required int coins,
  }) {
    final childRef = _child(uid, childId);
    final progressRef = childRef.collection('progress').doc(trackId);

    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(progressRef);
      final levels = (snap.data()?['levels'] as Map?) ?? const {};
      final previous = (levels[levelId] as num?)?.toInt();

      if (previous == null || stars > previous) {
        tx.set(
          progressRef,
          {
            'levels': {levelId: stars},
          },
          SetOptions(merge: true),
        );
      }

      final firstTime = previous == null;
      if (firstTime) {
        tx.update(childRef, {
          'xp': FieldValue.increment(xp),
          'coins': FieldValue.increment(coins),
        });
      }
      return firstTime;
    });
  }
}
