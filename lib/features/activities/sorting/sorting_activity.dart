import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/bin_catalog.dart';
import '../../../data/models/level.dart';
import '../../../data/models/sorting_level.dart';
import '../../tracks/providers/tracks_providers.dart';
import '../engine/activity_session.dart';
import '../engine/coming_soon_activity.dart';

final sortingLevelProvider = FutureProvider.family<SortingLevel, String>(
  (ref, levelId) => ref.watch(contentRepositoryProvider).loadSortingLevel(levelId),
);

/// Drag-and-drop sorting game: drag the item into the matching bin.
class SortingActivity extends ConsumerWidget {
  const SortingActivity({super.key, required this.level, required this.session});

  final Level level;
  final ActivitySession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(sortingLevelProvider(level.id));
    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      // No content file yet: keep the level playable.
      error: (e, _) => ComingSoonActivity(level: level, session: session),
      data: (level0) => level0.items.isEmpty
          ? ComingSoonActivity(level: level, session: session)
          : _SortingBody(data: level0, session: session),
    );
  }
}

class _SortingBody extends StatefulWidget {
  const _SortingBody({required this.data, required this.session});

  final SortingLevel data;
  final ActivitySession session;

  @override
  State<_SortingBody> createState() => _SortingBodyState();
}

class _SortingBodyState extends State<_SortingBody> {
  late final List<SortingItem> _items;
  int _step = 0;
  String? _flashBinId; // bin that just received a wrong drop

  @override
  void initState() {
    super.initState();
    _items = [...widget.data.items]..shuffle(Random());
    widget.session.begin(_items.length, hints: _items.first.hints);
  }

  void _onDrop(String binId) {
    final item = _items[_step];
    if (binId == item.binId) {
      final isLast = _step == _items.length - 1;
      widget.session.correct(
        nextHints: isLast ? const [] : _items[_step + 1].hints,
      );
      if (!isLast) setState(() => _step++);
    } else {
      widget.session.wrong();
      setState(() => _flashBinId = binId);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _flashBinId = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _items[_step];

    return Padding(
      padding: const EdgeInsets.all(AppSizes.padLarge),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Draggable<int>(
                data: _step,
                feedback: _ItemCard(item: item, dragging: true),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _ItemCard(item: item),
                ),
                child: _ItemCard(item: item),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.pad),
          Row(
            children: [
              for (final binId in widget.data.binIds) ...[
                Expanded(child: _BinTarget(
                  bin: BinCatalog.byId(binId),
                  flashing: _flashBinId == binId,
                  onDrop: () => _onDrop(binId),
                )),
                if (binId != widget.data.binIds.last)
                  const SizedBox(width: 12),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, this.dragging = false});

  final SortingItem item;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: dragging ? 8 : 2,
      borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      color: AppColors.surface,
      child: Container(
        width: 180,
        height: 180,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          border: Border.all(color: const Color(0xFFE3DCCB), width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _BinTarget extends StatelessWidget {
  const _BinTarget({
    required this.bin,
    required this.flashing,
    required this.onDrop,
  });

  final BinInfo bin;
  final bool flashing;
  final VoidCallback onDrop;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) => onDrop(),
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.isNotEmpty;
        final bg = flashing
            ? const Color(0xFFFFE2B8) // soft orange, never red
            : hovering
                ? bin.color.withValues(alpha: 0.35)
                : bin.color.withValues(alpha: 0.15);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 110,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppSizes.radius),
            border: Border.all(
              color: hovering ? bin.color : bin.color.withValues(alpha: 0.5),
              width: hovering ? 4 : 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(bin.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 4),
              Text(bin.label, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        );
      },
    );
  }
}
