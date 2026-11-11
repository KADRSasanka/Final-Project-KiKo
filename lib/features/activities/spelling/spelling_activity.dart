import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/level.dart';
import '../../../data/models/spelling_word.dart';
import '../../tracks/providers/tracks_providers.dart';
import '../engine/activity_session.dart';
import '../engine/coming_soon_activity.dart';

final spellingWordsProvider =
    FutureProvider.family<List<SpellingWord>, String>(
  (ref, levelId) => ref.watch(contentRepositoryProvider).loadSpellingWords(levelId),
);

/// Drag letter tiles into the slots to spell the word shown by the picture.
class SpellingActivity extends ConsumerWidget {
  const SpellingActivity({super.key, required this.level, required this.session});

  final Level level;
  final ActivitySession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(spellingWordsProvider(level.id));
    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      // No content file yet: keep the level playable.
      error: (e, _) => ComingSoonActivity(level: level, session: session),
      data: (words) => words.isEmpty
          ? ComingSoonActivity(level: level, session: session)
          : _SpellingBody(words: words, session: session),
    );
  }
}

class _Tile {
  const _Tile(this.id, this.letter);

  final int id;
  final String letter;
}

class _SpellingBody extends StatefulWidget {
  const _SpellingBody({required this.words, required this.session});

  final List<SpellingWord> words;
  final ActivitySession session;

  @override
  State<_SpellingBody> createState() => _SpellingBodyState();
}

class _SpellingBodyState extends State<_SpellingBody> {
  final _rng = Random();
  int _step = 0;
  late List<_Tile> _tray;
  late List<String?> _slots;
  int? _flashSlot; // slot that just received a wrong letter
  bool _busy = false;

  SpellingWord get _word => widget.words[_step];

  @override
  void initState() {
    super.initState();
    _setupWord();
    widget.session.begin(widget.words.length, hints: _word.hints);
  }

  void _setupWord() {
    final letters = _word.word.split('');
    final tiles = [
      for (var i = 0; i < letters.length; i++) _Tile(i, letters[i]),
    ];
    // Shuffle, but avoid handing over the word already solved.
    for (var tries = 0; tries < 5; tries++) {
      tiles.shuffle(_rng);
      if (tiles.map((t) => t.letter).join() != _word.word) break;
    }
    _tray = tiles;
    _slots = List<String?>.filled(letters.length, null);
  }

  void _onDrop(int slot, int tileId) {
    if (_busy || _slots[slot] != null) return;
    final index = _tray.indexWhere((t) => t.id == tileId);
    if (index < 0) return;
    final tile = _tray[index];

    if (tile.letter == _word.word[slot]) {
      setState(() {
        _slots[slot] = tile.letter;
        _tray.removeAt(index);
      });
      if (!_slots.contains(null)) _finishWord();
    } else {
      widget.session.wrong();
      setState(() => _flashSlot = slot);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _flashSlot = null);
      });
    }
  }

  Future<void> _finishWord() async {
    setState(() => _busy = true);
    final isLast = _step == widget.words.length - 1;
    widget.session.correct(
      nextHints: isLast ? const [] : widget.words[_step + 1].hints,
    );
    if (!isLast) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() {
        _step++;
        _setupWord();
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final word = _word;

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final available = constraints.maxWidth - AppSizes.padLarge * 2;
        final n = word.word.length;
        final slotSize =
            ((available - gap * (n - 1)) / n).clamp(36.0, 56.0).toDouble();

        return Padding(
          padding: const EdgeInsets.all(AppSizes.padLarge),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(word.emoji, style: const TextStyle(fontSize: 72)),
                        const SizedBox(height: 8),
                        Text(word.clue,
                            style: text.titleMedium, textAlign: TextAlign.center),
                        const SizedBox(height: AppSizes.padLarge),
                        Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          alignment: WrapAlignment.center,
                          children: [
                            for (var i = 0; i < n; i++)
                              _SlotBox(
                                size: slotSize,
                                letter: _slots[i],
                                flashing: _flashSlot == i,
                                onWillAccept: !_busy && _slots[i] == null,
                                onDrop: (tileId) => _onDrop(i, tileId),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  for (final t in _tray)
                    Draggable<int>(
                      key: ValueKey('${_step}_${t.id}'),
                      data: t.id,
                      feedback: _TileBox(letter: t.letter, dragging: true),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _TileBox(letter: t.letter),
                      ),
                      child: _TileBox(letter: t.letter),
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.pad),
            ],
          ),
        );
      },
    );
  }
}

class _TileBox extends StatelessWidget {
  const _TileBox({required this.letter, this.dragging = false});

  final String letter;
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
        width: 56,
        height: 56,
        child: Center(
          child: Text(letter, style: Theme.of(context).textTheme.headlineSmall),
        ),
      ),
    );
  }
}

class _SlotBox extends StatelessWidget {
  const _SlotBox({
    required this.size,
    required this.letter,
    required this.flashing,
    required this.onWillAccept,
    required this.onDrop,
  });

  final double size;
  final String? letter;
  final bool flashing;
  final bool onWillAccept;
  final ValueChanged<int> onDrop;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => onWillAccept,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.isNotEmpty;
        final filled = letter != null;

        final Color bg;
        final Color border;
        if (filled) {
          bg = AppColors.success;
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

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size,
          height: size + 8,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppSizes.radius * 0.7),
            border: Border.all(color: border, width: 3),
          ),
          child: filled
              ? Text(letter!, style: Theme.of(context).textTheme.headlineSmall)
              : null,
        );
      },
    );
  }
}
