import 'package:cloud_firestore/cloud_firestore.dart';

/// Stored at: users/{parentUid}/children/{childId}
class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.nickname,
    required this.avatarId,
    required this.age,
    this.xp = 0,
    this.coins = 0,
    this.createdAt,
  });

  final String id;
  final String nickname;
  final String avatarId;
  final int age;
  final int xp;
  final int coins;
  final DateTime? createdAt;

  factory ChildProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ChildProfile(
      id: doc.id,
      nickname: data['nickname'] as String? ?? 'Player',
      avatarId: data['avatarId'] as String? ?? 'fox',
      age: (data['age'] as num?)?.toInt() ?? 8,
      xp: (data['xp'] as num?)?.toInt() ?? 0,
      coins: (data['coins'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
