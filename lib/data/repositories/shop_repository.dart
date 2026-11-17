import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/shop_catalog.dart';

enum PurchaseResult { success, notEnoughCoins, alreadyOwned, notFound }

class ShopRepository {
  ShopRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _child(String uid, String childId) =>
      _db.collection('users').doc(uid).collection('children').doc(childId);

  /// Spends coins, adds the item to the child's collection and equips it.
  Future<PurchaseResult> buy({
    required String uid,
    required String childId,
    required String itemId,
  }) {
    final item = ShopCatalog.byId(itemId);
    if (item == null) return Future.value(PurchaseResult.notFound);
    final ref = _child(uid, childId);

    return _db.runTransaction<PurchaseResult>((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? const <String, dynamic>{};
      final coins = (data['coins'] as num?)?.toInt() ?? 0;
      final owned = List<String>.from((data['ownedItems'] as List?) ?? const []);
      final badges = List<String>.from((data['badges'] as List?) ?? const []);

      if (owned.contains(itemId)) return PurchaseResult.alreadyOwned;
      if (coins < item.price) return PurchaseResult.notEnoughCoins;

      final update = <String, Object?>{
        'coins': FieldValue.increment(-item.price),
        'ownedItems': FieldValue.arrayUnion([itemId]),
        'equipped.${item.slot}': itemId,
      };
      if (!badges.contains('first_purchase')) {
        update['badges'] = FieldValue.arrayUnion(['first_purchase']);
      }
      tx.update(ref, update);
      return PurchaseResult.success;
    });
  }

  /// Equip an owned item, or pass itemId = null to take the slot's item off.
  Future<void> equip({
    required String uid,
    required String childId,
    required String slot,
    String? itemId,
  }) {
    final Object value = itemId ?? FieldValue.delete();
    return _child(uid, childId).update({'equipped.$slot': value});
  }
}
