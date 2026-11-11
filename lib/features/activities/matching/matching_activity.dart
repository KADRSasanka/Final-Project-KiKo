import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/level.dart';
import '../../../data/models/matching_level.dart';
import '../../tracks/providers/tracks_providers.dart';
import '../engine/activity_session.dart';
import '../engine/coming_soon_activity.dart';

final matchingLevelProvider = FutureProvider.family<MatchingLevel, String>(
  (ref, levelId) => ref.watch(contentRepositoryProvider).loadMatchingLevel(levelId),
);

/// Drag each item onto its matching target (animal -> home, flag -> country...).
/// Used by 'matching', 'flag_match' and 'landmark_quest' levels.
class MatchingActivity extends ConsumerWidget {
  const MatchingActivity({super.key, required this.level, required this.session});

  final Level level;
  final ActivitySession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(matchingLevelProvider(level.id));
    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      // No content file yet: keep the level playable.
      error: (e, _) => ComingSoonActivity(level: level, session: session),
      data: (m) => m.pairs.isEmpty
          ? ComingSoonActivity(level: level, session: session)
          : _MatchingBody(data: m, session: session),
    );
  }
}

class _MatchingBody extends StatefulWidget {
  const _MatchingBody({required this.data, required this.session});

  final MatchingLevel data;
  final ActivitySession session;

  @override
  State<_MatchingBody> createState() => _MatchingBodyState();
}

class _MatchingBodyState extends State<_MatchingBody> {
  late final List<MatchPair> _itemOrder;
  late final List<MatchPair> _targetOrder;
  final Set<int> _matched = {};
  int? _flashTargetId; // target that just received a wrong drop

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _itemOrder = [...widget.data.pairs]..shuffle(rng);
    _targetOrder = [...widget.data.pairs]..shuffle(rng);
    widget.session.begin(widget.data.pairs.length, hints: _nextHints());
  }

  /// Hints for the first item still waiting to be matched.
  List<String> _nextHints() {
    for (final p in _itemOrder) {
      if (!_matched.contains(p.id)) return p.hints;
    }
    return const [];
  }

  void _onDrop(int itemId, int targetId) {
    if (_matched.contains(itemId)) return;

    if (itemId == targetId) {
      setState(() => _matched.add(itemId));
      widget.session.correct(nextHints: _nextHints());
    } else {
      widget.session.wrong();
      setState(() => _flashTargetId = targetId);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _flashTargetId = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final remaining = [
      for (final p in _itemOrder)
        if (!_matched.contains(p.id)) p,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final cardWidth =
            (constraints.maxWidth - AppSizes.padLarge * 2 - gap) / 2;

        return Padding(
          padding: const EdgeInsets.all(AppSizes.padLarge),
          child: Column(
            children: [
              Text(widget.data.prompt,
                  style: text.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: AppSizes.pad),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final p in remaining)
                          Draggable<int>(
                            key: ValueKey(p.id),
                            data: p.id,
                            feedback: _ItemChip(pair: p, dragging: true),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: _ItemChip(pair: p),
                            ),
                            child: _ItemChip(pair: p),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.pad),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                alignment: WrapAlignment.center,
                children: [
                  for (final p in _targetOrder)
                    _TargetCard(
                      pair: p,
                      width: cardWidth,
                      matched: _matched.contains(p.id),
                      flashing: _flashTargetId == p.id,
                      onDrop: (itemId) => _onDrop(itemId, p.id),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ItemChip extends StatelessWidget {
  const _ItemChip({required this.pair, this.dragging = false});

  final MatchPair pair;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: dragging ? 8 : 2,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        side: const BorderSide(color: Color(0xFFE3DCCB), width: 3),
      ),
      child: SizedBox(
        width: 88,
        height: 96,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (pair.itemEmoji.isNotEmpty)
              Text(pair.itemEmoji, style: const TextStyle(fontSize: 40)),
            if (pair.itemLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    pair.itemLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({
    required this.pair,
    required this.width,
    required this.matched,
    required this.flashing,
    required this.onDrop,
  });

  final MatchPair pair;
  final double width;
  final bool matched;
  final bool flashing;
  final ValueChanged<int> onDrop;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => !matched,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.isNotEmpty;

        final Color bg;
        final Color border;
        if (matched) {
          bg = AppColors.success.withValues(alpha: 0.3);
          border = AppColors.success;
        } else if (flashing) {
          bg = const Color(0xFFFFE2B8); // soft orange, never red
          border = AppColors.tryAgain;
        } else if (hovering) {
          bg = AppColors.primary.withValues(alpha: 0.15);
          border = AppColors.primary;
        } else {
          bg = AppColors.surface;
          border = const Color(0xFFE3DCCB);
        }

        final topEmoji = matched
            ? (pair.itemEmoji.isEmpty ? '✅' : pair.itemEmoji)
            : pair.targetEmoji;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: width,
          height: 104,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppSizes.radius),
            border: Border.all(color: border, width: hovering ? 4 : 3),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (topEmoji.isNotEmpty)
                Text(topEmoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(pair.targetLabel, style: text.titleSmall),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
