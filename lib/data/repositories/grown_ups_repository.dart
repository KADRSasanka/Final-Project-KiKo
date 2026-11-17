import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/day_key.dart';
import '../models/track_progress.dart';

/// Data for the Grown-ups tab: progress overview, play time, time limit.
class GrownUpsRepository {
  GrownUpsRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _child(String uid, String childId) =>
      _db.collection('users').doc(uid).collection('children').doc(childId);

  /// Live progress of every track (key = track id).
  Stream<Map<String, TrackProgress>> watchAllProgress(
    String uid,
    String childId,
  ) {
    return _child(uid, childId).collection('progress').snapshots().map(
          (snap) => {
            for (final d in snap.docs) d.id: TrackProgress.fromData(d.data()),
          },
        );
  }

  /// Adds seconds of play time to today's total.
  Future<void> addPlaySeconds({
    required String uid,
    required String childId,
    required int seconds,
  }) {
    if (seconds <= 0) return Future.value();
    return _child(uid, childId).update({
      'playSeconds.${todayCompact()}': FieldValue.increment(seconds),
    });
  }

  /// 0 = no limit.
  Future<void> setDailyLimit({
    required String uid,
    required String childId,
    required int minutes,
  }) =>
      _child(uid, childId).update({'dailyLimitMinutes': minutes});
}
