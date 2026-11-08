import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/child_profile.dart';
import '../../../data/repositories/child_repository.dart';
import '../../auth/providers/auth_providers.dart';

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final childRepositoryProvider = Provider<ChildRepository>(
  (ref) => ChildRepository(ref.watch(firestoreProvider)),
);

/// All child profiles of the signed-in grown-up (live).
final childrenProvider = StreamProvider<List<ChildProfile>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(const <ChildProfile>[]);
  return ref.watch(childRepositoryProvider).watchChildren(user.uid);
});

/// Which child is playing right now.
final activeChildIdProvider = StateProvider<String?>((ref) => null);

/// The active child, kept live so XP/coins update on screen.
final activeChildProvider = Provider<ChildProfile?>((ref) {
  final id = ref.watch(activeChildIdProvider);
  final children = ref.watch(childrenProvider).valueOrNull ?? const [];
  for (final child in children) {
    if (child.id == id) return child;
  }
  return null;
});
