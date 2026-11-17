import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/track_progress.dart';
import '../../../data/repositories/grown_ups_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../profile/providers/profile_providers.dart';

final grownUpsRepositoryProvider = Provider<GrownUpsRepository>(
  (ref) => GrownUpsRepository(ref.watch(firestoreProvider)),
);

/// When the Grown-ups tab was unlocked (valid until this time).
/// Watching the active player means it re-locks when the player changes
/// or when someone signs out.
final grownUpUnlockedUntilProvider = StateProvider<DateTime?>((ref) {
  ref.watch(activeChildIdProvider);
  return null;
});

/// Progress of all tracks for one child (key = child id).
final allProgressProvider =
    StreamProvider.family<Map<String, TrackProgress>, String>((ref, childId) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const <String, TrackProgress>{});
  return ref.watch(grownUpsRepositoryProvider).watchAllProgress(uid, childId);
});

/// True when the active player has used up today's time limit.
final isTimeUpProvider = Provider<bool>(
  (ref) => ref.watch(activeChildProvider)?.isTimeUp ?? false,
);
