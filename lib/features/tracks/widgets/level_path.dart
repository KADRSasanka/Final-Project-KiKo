import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/level.dart';
import '../../../data/models/track_progress.dart';

/// Winding path of level bubbles (locked / current / done).
class LevelPath extends StatelessWidget {
  const LevelPath({
    super.key,
    required this.levels,
    required this.progress,
    required this.color,
    required this.onLevelTap,
  });

  final List<Level> levels;
  final TrackProgress progress;
  final Color color;
  final ValueChanged<Level> onLevelTap;

  static const _rowHeight = 140.0;
  static const _nodeSize = 76.0;
  static const _cellWidth = 120.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final points = [
          for (var i = 0; i < levels.length; i++)
            Offset(
              width / 2 + math.sin(i * math.pi / 2) * width * 0.26,
              _rowHeight * i + _rowHeight / 2,
            ),
        ];

        return SizedBox(
          height: _rowHeight * levels.length,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _DotPathPainter(points, color)),
              ),
              for (var i = 0; i < levels.length; i++)
                Positioned(
                  left: points[i].dx - _cellWidth / 2,
                  top: points[i].dy - _nodeSize / 2,
                  child: _LevelNode(
                    level: levels[i],
                    state: _stateOf(i),
                    stars: progress.starsFor(levels[i].id),
                    color: color,
                    onTap: () => onLevelTap(levels[i]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  _NodeState _stateOf(int i) {
    if (progress.isDone(levels[i].id)) return _NodeState.done;
    return progress.isUnlocked(levels, i) ? _NodeState.current : _NodeState.locked;
  }
}

enum _NodeState { locked, current, done }

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.level,
    required this.state,
    required this.stars,
    required this.color,
    required this.onTap,
  });

  final Level level;
  final _NodeState state;
  final int stars;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final locked = state == _NodeState.locked;

    return SizedBox(
      width: LevelPath._cellWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: LevelPath._nodeSize,
              height: LevelPath._nodeSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: locked ? const Color(0xFFD9D4C7) : color,
                border: state == _NodeState.current
                    ? Border.all(color: AppColors.sunshine, width: 6)
                    : null,
                boxShadow: locked
                    ? null
                    : [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: locked
                  ? const Icon(Icons.lock, color: Colors.white, size: 32)
                  : Text('${level.number}', style: text.headlineSmall),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var s = 1; s <= 3; s++)
                Icon(
                  s <= stars ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 18,
                  color: s <= stars
                      ? AppColors.sunshine
                      : const Color(0xFFCFC8B8),
                ),
            ],
          ),
          Text(
            level.title,
            style: text.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DotPathPainter extends CustomPainter {
  _DotPathPainter(this.points, this.color);

  final List<Offset> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()..color = color.withValues(alpha: 0.35);

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final midY = (a.dy + b.dy) / 2;
      path.cubicTo(a.dx, midY, b.dx, midY, b.dx, b.dy);
    }

    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 16) {
        final tangent = metric.getTangentForOffset(d);
        if (tangent != null) canvas.drawCircle(tangent.position, 4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPathPainter old) => true;
}
