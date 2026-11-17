import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/level.dart';
import '../../../data/models/level_completion.dart';
import '../../auth/providers/auth_providers.dart';
import '../../grown_ups/providers/grown_ups_providers.dart';
import '../../grown_ups/services/play_time_tracker.dart';
import '../../grown_ups/widgets/time_up_dialog.dart';
import '../../profile/providers/profile_providers.dart';
import '../../tracks/providers/tracks_providers.dart';
import '../engine/activity_registry.dart';
import '../engine/activity_session.dart';
import '../widgets/feedback_banner.dart';
import '../widgets/hint_bubble.dart';
import '../widgets/result_view.dart';
import '../widgets/step_dots.dart';

/// The play screen. It hosts any activity and adds the shared parts:
/// progress dots, feedback, hints, stars, saving and the result screen.
class ActivityHostScreen extends ConsumerStatefulWidget {
  const ActivityHostScreen({
    super.key,
    required this.trackId,
    required this.levelId,
  });

  final String trackId;
  final String levelId;

  @override
  ConsumerState<ActivityHostScreen> createState() => _ActivityHostScreenState();
}

class _Result {
  const _Result({
    required this.stars,
    this.completion,
    this.saving = false,
    this.saveFailed = false,
  });

  final int stars;
  final LevelCompletion? completion;
  final bool saving;
  final bool saveFailed;
}

class _ActivityHostScreenState extends ConsumerState<ActivityHostScreen> {
  late ActivitySession _session;
  late final PlayTimeTracker _tracker;
  int _run = 0; // changes on "Play again" to rebuild the activity fresh
  bool _completing = false;
  _Result? _result;

  @override
  void initState() {
    super.initState();
    _session = ActivitySession()..addListener(_onSession);

    // Count play time for the Grown-ups tab and the daily time limit.
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    final childId = ref.read(activeChildIdProvider);
    final repo = ref.read(grownUpsRepositoryProvider);
    _tracker = PlayTimeTracker(
      onFlush: (seconds) {
        if (uid == null || childId == null) return Future.value();
        return repo.addPlaySeconds(uid: uid, childId: childId, seconds: seconds);
      },
    )..start();
  }

  @override
  void dispose() {
    _tracker.stop();
    _session.removeListener(_onSession);
    _session.dispose();
    super.dispose();
  }

  Level? _find(List<Level>? levels) {
    for (final l in levels ?? const <Level>[]) {
      if (l.id == widget.levelId) return l;
    }
    return null;
  }

  void _onSession() {
    if (_session.finished && !_completing) {
      _completing = true;
      _complete();
    }
  }

  Future<void> _complete() async {
    // Let the last "Great job!" show for a moment.
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final level = _find(ref.read(levelsProvider(widget.trackId)).valueOrNull);
    if (level == null) return;
    await _save(level, _session.stars);
  }

  Future<void> _save(Level level, int stars) async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    final childId = ref.read(activeChildIdProvider);
    if (uid == null || childId == null) return;

    setState(() => _result = _Result(stars: stars, saving: true));
    try {
      final levelCount =
          ref.read(levelsProvider(widget.trackId)).valueOrNull?.length ?? 5;
      final completion = await ref.read(progressRepositoryProvider).completeLevel(
            uid: uid,
            childId: childId,
            trackId: widget.trackId,
            levelId: level.id,
            stars: stars,
            xp: level.xp,
            coins: level.coins,
            trackLevelCount: levelCount,
          );
      if (!mounted) return;
      setState(() => _result = _Result(stars: stars, completion: completion));
    } catch (_) {
      if (!mounted) return;
      setState(() => _result = _Result(stars: stars, saveFailed: true));
    }
  }

  void _replay() {
    // The level that was just finished may have used up today's time.
    if (ref.read(isTimeUpProvider)) {
      showTimeUpDialog(context);
      return;
    }
    _session.removeListener(_onSession);
    _session.dispose();
    setState(() {
      _session = ActivitySession()..addListener(_onSession);
      _run++;
      _completing = false;
      _result = null;
    });
  }

  void _continue(Level level, _Result result) {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    router.pop(); // play -> intro
    router.pop(); // intro -> track
    if (result.completion?.firstTime ?? false) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Great job! +${level.xp} XP  +${level.coins} coins'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final levels = ref.watch(levelsProvider(widget.trackId)).valueOrNull;
    final level = _find(levels);
    final result = _result;

    return Scaffold(
      appBar: AppBar(title: Text(level?.title ?? '')),
      body: SafeArea(
        child: level == null
            ? const Center(child: CircularProgressIndicator())
            : result != null
                ? ResultView(
                    stars: result.stars,
                    xp: level.xp,
                    coins: level.coins,
                    completion: result.completion,
                    saving: result.saving,
                    saveFailed: result.saveFailed,
                    onContinue: () => _continue(level, result),
                    onReplay: _replay,
                    onRetry: () => _save(level, result.stars),
                  )
                : _buildPlay(level),
      ),
    );
  }

  Widget _buildPlay(Level level) {
    final activity = KeyedSubtree(
      key: ValueKey(_run),
      child: ActivityRegistry.build(level, _session),
    );

    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) {
        final showHintButton = _session.totalSteps > 0 && !_session.finished;
        return Column(
          children: [
            if (_session.totalSteps > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: StepDots(
                  current: _session.currentStep,
                  total: _session.totalSteps,
                ),
              ),
            Expanded(child: activity),
            HintBubble(hint: _session.currentHint),
            FeedbackBanner(
              kind: _session.feedback,
              text: _session.feedbackText,
            ),
            if (showHintButton)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _session.hasMoreHints ? _session.useHint : null,
                    icon: const Icon(Icons.lightbulb_outline),
                    label: Text(
                      _session.hintsShown == 0
                          ? 'Need a hint?'
                          : _session.hasMoreHints
                              ? 'Another hint'
                              : 'No more hints',
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
