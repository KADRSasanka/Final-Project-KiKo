import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/level.dart';
import '../../../data/models/track_progress.dart';
import '../../../data/repositories/content_repository.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../profile/providers/profile_providers.dart';

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => ContentRepository(),
);

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(ref.watch(firestoreProvider)),
);

/// Levels of one track (family key = track id, e.g. 'math').
final levelsProvider = FutureProvider.family<List<Level>, String>(
  (ref, trackId) => ref.watch(contentRepositoryProvider).loadLevels(trackId),
);

/// Live progress of the active player in one track.
final trackProgressProvider =
    StreamProvider.family<TrackProgress, String>((ref, trackId) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  final childId = ref.watch(activeChildIdProvider);
  if (uid == null || childId == null) {
    return Stream.value(const TrackProgress());
  }
  return ref.watch(progressRepositoryProvider).watchTrack(uid, childId, trackId);
});
