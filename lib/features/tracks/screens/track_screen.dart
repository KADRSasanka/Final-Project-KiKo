import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/level.dart';
import '../../../data/models/track_progress.dart';
import '../providers/tracks_providers.dart';
import '../widgets/level_path.dart';

class TrackScreen extends ConsumerWidget {
  const TrackScreen({super.key, required this.trackId});

  final String trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final track = Track.values.asNameMap()[trackId];

    if (track == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Track not found', style: text.bodyLarge)),
      );
    }

    final levels = ref.watch(levelsProvider(trackId));
    final progress =
        ref.watch(trackProgressProvider(trackId)).valueOrNull ??
            const TrackProgress();

    return Scaffold(
      appBar: AppBar(title: Text(track.label)),
      body: levels.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Could not load levels.', style: text.bodyLarge),
        ),
        data: (list) {
          final done = progress.doneIn(list);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.pad),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.pad),
                  decoration: BoxDecoration(
                    color: track.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSizes.radius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$done of ${list.length} levels done',
                          style: text.titleMedium),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: list.isEmpty ? 0 : done / list.length,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.padLarge),
                LevelPath(
                  levels: list,
                  progress: progress,
                  color: track.color,
                  onLevelTap: (level) =>
                      _open(context, list, progress, level),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _open(
    BuildContext context,
    List<Level> levels,
    TrackProgress progress,
    Level level,
  ) {
    if (!progress.isUnlocked(levels, level.index)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finish the last level to open this one!')),
      );
      return;
    }
    context.push(AppRoutes.levelPath(trackId, level.id));
  }
}
