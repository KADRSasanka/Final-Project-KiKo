import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/level.dart';
import '../../../data/models/number_bridge_question.dart';
import '../../tracks/providers/tracks_providers.dart';
import '../engine/activity_session.dart';
import '../engine/coming_soon_activity.dart';

final numberBridgeProvider =
    FutureProvider.family<List<NumberBridgeQuestion>, String>(
  (ref, levelId) => ref.watch(contentRepositoryProvider).loadNumberBridge(levelId),
);

/// The bridge is an equation made of planks with one missing.
/// Drag the right number into the gap, then the walker crosses.
class NumberBridgeActivity extends ConsumerWidget {
  const NumberBridgeActivity({
    super.key,
    required this.level,
    required this.session,
  });

  final Level level;
  final ActivitySession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(numberBridgeProvider(level.id));
    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      // No content file yet: keep the level playable.
      error: (e, _) => ComingSoonActivity(level: level, session: session),
      data: (list) => list.isEmpty
          ? ComingSoonActivity(level: level, session: session)
          : _BridgeBody(questions: list, session: session),
    );
  }
}

const _woodLight = Color(0xFFE9C48D);
const _woodDark = Color(0xFFC99A5B);
const _water = Color(0xFFCFEFFF);

class _BridgeBody extends StatefulWidget {
  const _BridgeBody({required this.questions, required this.session});

  final List<NumberBridgeQuestion> questions;
  final ActivitySession session;

  @override
  State<_BridgeBody> createState() => _BridgeBodyState();
}

class _BridgeBodyState extends State<_BridgeBody> {
  final _rng = Random();
  int _step = 0;
  bool _solved = false;
  bool _flash = false; // gap flashes after a wrong number
  late List<int> _options;

  NumberBridgeQuestion get _q => widget.questions[_step];

  @override
  void initState() {
    super.initState();
    _shuffleOptions();
    widget.session.begin(widget.questions.length, hints: _q.hints);
  }

  void _shuffleOptions() => _options = [..._q.options]..shuffle(_rng);

  void _onDrop(int value) {
    if (_solved) return;
    if (value == _q.answer) {
      _correct();
    } else {
      widget.session.wrong();
      setState(() => _flash = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _flash = false);
      });
    }
  }

  Future<void> _correct() async {
    setState(() => _solved = true);
    final isLast = _step == widget.questions.length - 1;
    widget.session.correct(
      nextHints: isLast ? const [] : widget.questions[_step + 1].hints,
    );
    if (isLast) return;

    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() {
      _step++;
      _solved = false;
      _shuffleOptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final q = _q;

    return Padding(
      padding: const EdgeInsets.all(AppSizes.padLarge),
      child: Column(
        children: [
          Text('Fix the bridge!',
              style: text.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('Drag the missing number into the gap.',
              style: text.bodyMedium, textAlign: TextAlign.center),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Walker(key: ValueKey(_step), crossing: _solved),
                    _Bridge(
                      tokens: q.tokens,
                      answer: q.answer,
                      solved: _solved,
                      flashing: _flash,
                      onDrop: _onDrop,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (final n in _options)
                Draggable<int>(
                  key: ValueKey('${_step}_$n'),
                  data: n,
                  maxSimultaneousDrags: _solved ? 0 : 1,
                  feedback: _NumberTile(value: n, dragging: true),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _NumberTile(value: n),
                  ),
                  child: _NumberTile(value: n),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.pad),
        ],
      ),
    );
  }
}

/// A little walker that crosses the bridge once the gap is fixed.
class _Walker extends StatelessWidget {
  const _Walker({super.key, required this.crossing});

  final bool crossing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: crossing ? 1 : 0),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
        builder: (context, t, child) => Align(
          alignment: Alignment(-1 + 2 * t, 0),
          child: child,
        ),
        child: const Text('🚶', style: TextStyle(fontSize: 32)),
      ),
    );
  }
}

class _Bridge extends StatelessWidget {
  const _Bridge({
    required this.tokens,
    required this.answer,
    required this.solved,
    required this.flashing,
    required this.onDrop,
  });

  final List<String> tokens;
  final int answer;
  final bool solved;
  final bool flashing;
  final ValueChanged<int> onDrop;

  static const _bank = 26.0;
  static const _gap = 6.0;

  static bool _isOperator(String t) => int.tryParse(t) == null && t != '?';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final n = tokens.length;
        final avail = c.maxWidth - 2 * _bank - _gap * (n + 1);
        final plankW = (avail / n).clamp(40.0, 64.0).toDouble();

        return Container(
          height: 120,
          decoration: BoxDecoration(
            color: _water,
            borderRadius: BorderRadius.circular(AppSizes.radius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _Bank(),
              const SizedBox(width: _gap),
              for (final t in tokens) ...[
                if (t == '?')
                  _GapPlank(
                    width: plankW,
                    answer: answer,
                    solved: solved,
                    flashing: flashing,
                    onDrop: onDrop,
                  )
                else
                  _Plank(label: t, width: plankW, dark: _isOperator(t)),
                const SizedBox(width: _gap),
              ],
              const _Bank(),
            ],
          ),
        );
      },
    );
  }
}

class _Bank extends StatelessWidget {
  const _Bank();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _Bridge._bank,
      height: 120,
      decoration: const BoxDecoration(
        color: Color(0xFF7ED6A5),
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(AppSizes.radius),
          right: Radius.circular(AppSizes.radius),
        ),
      ),
    );
  }
}

class _Plank extends StatelessWidget {
  const _Plank({required this.label, required this.width, required this.dark});

  final String label;
  final double width;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 64,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: dark ? _woodDark : _woodLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9C7440), width: 2),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}

class _GapPlank extends StatelessWidget {
  const _GapPlank({
    required this.width,
    required this.answer,
    required this.solved,
    required this.flashing,
    required this.onDrop,
  });

  final double width;
  final int answer;
  final bool solved;
  final bool flashing;
  final ValueChanged<int> onDrop;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => !solved,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.isNotEmpty;

        final Color bg;
        final Color border;
        if (solved) {
          bg = AppColors.success;
          border = AppColors.success;
        } else if (flashing) {
          bg = const Color(0xFFFFE2B8); // soft orange, never red
          border = AppColors.tryAgain;
        } else if (hovering) {
          bg = AppColors.primary.withValues(alpha: 0.2);
          border = AppColors.primary;
        } else {
          bg = Colors.white.withValues(alpha: 0.7);
          border = AppColors.sunshine;
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: width,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 3),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              solved ? '$answer' : '?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        );
      },
    );
  }
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({required this.value, this.dragging = false});

  final int value;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: dragging ? 8 : 2,
      color: AppColors.sunshine,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Center(
          child: Text('$value', style: Theme.of(context).textTheme.headlineSmall),
        ),
      ),
    );
  }
}
