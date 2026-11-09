import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/fraction_question.dart';
import '../../../data/models/level.dart';
import '../../tracks/providers/tracks_providers.dart';
import '../engine/activity_session.dart';
import '../engine/coming_soon_activity.dart';

final fractionQuestionsProvider =
    FutureProvider.family<List<FractionQuestion>, String>(
  (ref, levelId) =>
      ref.watch(contentRepositoryProvider).loadFractionQuestions(levelId),
);

/// Drag pizza slices onto the plate to build the target fraction.
class FractionPizzaActivity extends ConsumerWidget {
  const FractionPizzaActivity({
    super.key,
    required this.level,
    required this.session,
  });

  final Level level;
  final ActivitySession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(fractionQuestionsProvider(level.id));
    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      // No content file yet: keep the level playable.
      error: (e, _) => ComingSoonActivity(level: level, session: session),
      data: (list) => list.isEmpty
          ? ComingSoonActivity(level: level, session: session)
          : _FractionBody(questions: list, session: session),
    );
  }
}

class _FractionBody extends StatefulWidget {
  const _FractionBody({required this.questions, required this.session});

  final List<FractionQuestion> questions;
  final ActivitySession session;

  @override
  State<_FractionBody> createState() => _FractionBodyState();
}

class _FractionBodyState extends State<_FractionBody> {
  int _step = 0;
  int _filled = 0;
  bool _busy = false;

  FractionQuestion get _question => widget.questions[_step];

  @override
  void initState() {
    super.initState();
    widget.session.begin(widget.questions.length, hints: _question.hints);
  }

  void _addSlice() {
    if (_busy || _filled >= _question.denominator) return;
    setState(() => _filled++);
  }

  void _removeSlice() {
    if (_busy || _filled <= 0) return;
    setState(() => _filled--);
  }

  Future<void> _serve() async {
    if (_busy) return;
    final q = _question;

    if (_filled == q.numerator) {
      setState(() => _busy = true);
      final isLast = _step == widget.questions.length - 1;
      widget.session.correct(
        nextHints: isLast ? const [] : widget.questions[_step + 1].hints,
      );
      if (!isLast) {
        await Future.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        setState(() {
          _step++;
          _filled = 0;
          _busy = false;
        });
      }
    } else {
      widget.session.wrong();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final q = _question;

    return Padding(
      padding: const EdgeInsets.all(AppSizes.padLarge),
      child: Column(
        children: [
          Text('Make ${q.label} of the pizza',
              style: text.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSizes.pad),
          Expanded(
            child: Center(
              child: DragTarget<int>(
                onWillAcceptWithDetails: (_) => _filled < q.denominator,
                onAcceptWithDetails: (_) => _addSlice(),
                builder: (context, candidateData, rejectedData) {
                  return _Pizza(
                    total: q.denominator,
                    filled: _filled,
                    highlighted: candidateData.isNotEmpty,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('$_filled of ${q.denominator} slices', style: text.bodyMedium),
          const SizedBox(height: AppSizes.pad),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filled(
                onPressed: _removeSlice,
                icon: const Icon(Icons.remove),
                tooltip: 'Take a slice off',
              ),
              const SizedBox(width: 20),
              Draggable<int>(
                data: 0,
                feedback: const _SliceChip(dragging: true),
                childWhenDragging: const Opacity(
                  opacity: 0.3,
                  child: _SliceChip(),
                ),
                child: const _SliceChip(),
              ),
              const SizedBox(width: 20),
              IconButton.filled(
                onPressed: _addSlice,
                icon: const Icon(Icons.add),
                tooltip: 'Add a slice',
              ),
            ],
          ),
          const SizedBox(height: AppSizes.pad),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy ? null : _serve,
              child: const Text('Serve it! 🍽️'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliceChip extends StatelessWidget {
  const _SliceChip({this.dragging = false});

  final bool dragging;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: dragging ? 6 : 0,
      color: Colors.transparent,
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.orange, width: 3),
        ),
        child: const Text('🍕', style: TextStyle(fontSize: 32)),
      ),
    );
  }
}

/// A pizza divided into equal wedges; the first [filled] are topped.
class _Pizza extends StatelessWidget {
  const _Pizza({
    required this.total,
    required this.filled,
    required this.highlighted,
  });

  final int total;
  final int filled;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: highlighted ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: SizedBox(
        width: 220,
        height: 220,
        child: CustomPaint(
          painter: _PizzaPainter(total: total, filled: filled),
        ),
      ),
    );
  }
}

class _PizzaPainter extends CustomPainter {
  _PizzaPainter({required this.total, required this.filled});

  final int total;
  final int filled;

  static const _crustColor = Color(0xFFB5834C);
  static const _baseColor = Color(0xFFFFE8B8);
  static const _toppingColor = Color(0xFFE8622C);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    final sweep = (2 * math.pi) / total;
    final divider = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (var i = 0; i < total; i++) {
      final start = -math.pi / 2 + i * sweep;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          start,
          sweep,
          false,
        )
        ..close();

      final fill = Paint()
        ..color = i < filled ? _toppingColor : _baseColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fill);
      canvas.drawPath(path, divider);
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _crustColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );
  }

  @override
  bool shouldRepaint(covariant _PizzaPainter old) =>
      old.total != total || old.filled != filled;
}
