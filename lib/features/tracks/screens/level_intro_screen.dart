import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/activity_info.dart';
import '../../../data/models/level.dart';
import '../../../data/models/track_progress.dart';
import '../providers/tracks_providers.dart';

class LevelIntroScreen extends ConsumerWidget {
  const LevelIntroScreen({
    super.key,
    required this.trackId,
    required this.levelId,
  });

  final String trackId;
  final String levelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final track = Track.values.asNameMap()[trackId];
    final levels = ref.watch(levelsProvider(trackId));
    final progress =
        ref.watch(trackProgressProvider(trackId)).valueOrNull ??
            const TrackProgress();

    return Scaffold(
      appBar: AppBar(title: Text(track?.label ?? '')),
      body: levels.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Could not load this level.', style: text.bodyLarge),
        ),
        data: (list) {
          Level? level;
          for (final l in list) {
            if (l.id == levelId) level = l;
          }
          if (level == null) {
            return Center(child: Text('Level not found', style: text.bodyLarge));
          }
          return _Content(
            level: level,
            color: track?.color ?? AppColors.primary,
            bestStars: progress.starsFor(level.id),
            onStart: () => context.push(AppRoutes.playPath(trackId, level!.id)),
          );
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.level,
    required this.color,
    required this.bestStars,
    required this.onStart,
  });

  final Level level;
  final Color color;
  final int bestStars;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final info = ActivityInfo.of(level.activity);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.padLarge),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 140,
              height: 140,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.25),
              ),
              child: Text(info.emoji, style: const TextStyle(fontSize: 72)),
            ),
            const SizedBox(height: AppSizes.padLarge),
            Text('Level ${level.number}', style: text.bodyLarge),
            Text(level.title,
                style: text.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(info.label, style: text.bodyLarge),
            const SizedBox(height: AppSizes.padLarge),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _Pill('⏱ ~${level.minutes} min'),
                _Pill('⭐ +${level.xp} XP'),
                _Pill('🪙 +${level.coins}'),
              ],
            ),
            if (bestStars > 0) ...[
              const SizedBox(height: AppSizes.pad),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Your best: ', style: text.bodyMedium),
                  for (var s = 1; s <= 3; s++)
                    Icon(
                      s <= bestStars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: AppColors.sunshine,
                    ),
                ],
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onStart,
                child: Text(bestStars > 0 ? 'Play again' : "Let's go!"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Text(label, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
