import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/child_profile.dart';

class ChildRepository {
  ChildRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('children');

  Stream<List<ChildProfile>> watchChildren(String uid) {
    return _col(uid).snapshots().map((snap) {
      final list = snap.docs.map(ChildProfile.fromDoc).toList();
      // Oldest first; docs with a pending server timestamp go last.
      list.sort((a, b) {
        final at = a.createdAt;
        final bt = b.createdAt;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return at.compareTo(bt);
      });
      return list;
    });
  }

  Future<void> addChild(
    String uid, {
    required String nickname,
    required String avatarId,
    required int age,
  }) {
    return _col(uid).add({
      'nickname': nickname,
      'avatarId': avatarId,
      'age': age,
      'xp': 0,
      'coins': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteChild(String uid, String childId) =>
      _col(uid).doc(childId).delete();
}
