import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/activity_info.dart';
import '../../../data/models/level.dart';
import '../../auth/providers/auth_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/tracks_providers.dart';

/// TEMPORARY placeholder. The real activity screens replace this later.
/// The test button saves 3 stars so you can check unlocking + XP.
class LevelPlayScreen extends ConsumerStatefulWidget {
  const LevelPlayScreen({
    super.key,
    required this.trackId,
    required this.levelId,
  });

  final String trackId;
  final String levelId;

  @override
  ConsumerState<LevelPlayScreen> createState() => _LevelPlayScreenState();
}

class _LevelPlayScreenState extends ConsumerState<LevelPlayScreen> {
  bool _saving = false;

  Future<void> _finish(Level level) async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    final childId = ref.read(activeChildIdProvider);
    if (uid == null || childId == null) return;

    setState(() => _saving = true);
    try {
      final firstTime = await ref.read(progressRepositoryProvider).completeLevel(
            uid: uid,
            childId: childId,
            trackId: widget.trackId,
            levelId: level.id,
            stars: 3,
            xp: level.xp,
            coins: level.coins,
          );
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      final router = GoRouter.of(context);
      router.pop(); // play -> intro
      router.pop(); // intro -> track
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            firstTime
                ? 'Great job! +${level.xp} XP  +${level.coins} coins'
                : 'Nice replay!',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final levels = ref.watch(levelsProvider(widget.trackId)).valueOrNull;

    Level? level;
    for (final l in levels ?? const <Level>[]) {
      if (l.id == widget.levelId) level = l;
    }
    final info = ActivityInfo.of(level?.activity ?? '');

    return Scaffold(
      appBar: AppBar(title: Text(level?.title ?? '')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(info.emoji,
                  style: const TextStyle(fontSize: 80),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text('${info.label} is coming soon!',
                  style: text.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed:
                    (_saving || level == null) ? null : () => _finish(level!),
                child: const Text('Finish level (test)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
